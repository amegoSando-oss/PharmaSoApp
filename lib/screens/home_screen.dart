import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/hero_page_route.dart';
import '../core/realtime_client.dart';
import '../core/text_utils.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/offers_service.dart';
import '../services/quotations_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/language_toggle.dart';
import '../widgets/notification_bell.dart';
import '../widgets/offline_sync_status_button.dart';
import '../widgets/premium_menu_card.dart';
import '../widgets/quick_stat_tile.dart';
import 'create_offer_screen.dart';
import 'login_screen.dart';
import 'price_offers_screen.dart';
import 'quotations_screen.dart';
import 'sales_orders_screen.dart';

String _greetingForHour(AppLocalizations l10n, int hour) {
  if (hour < 12) return l10n.homeGreetingMorning;
  if (hour < 17) return l10n.homeGreetingAfternoon;
  return l10n.homeGreetingEvening;
}

/// The app's hub: a greeting header, a quick-stats row, and three dropdown
/// menus (Price Offer / Quotation / Sales Order) that navigate to their own
/// dedicated screens — see price_offers_screen.dart, quotations_screen.dart,
/// sales_orders_screen.dart.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _statsLoading = true;
  int? _openRequests;
  int? _pendingQuotations;
  int? _draftPriceOffers;

  Timer? _statsPollTimer;
  final List<VoidCallback> _unsubscribeLiveUpdates = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Real-time: the same two channels the price-offers/quotations list
    // screens already subscribe to also cover every transition that can move
    // these counts, so re-fetch on either instead of waiting for the user to
    // navigate away and back. A 90s poll covers Reverb not running.
    final realtime = context.read<RealtimeClient>();
    _statsPollTimer = Timer.periodic(
      const Duration(seconds: 90),
      (_) => _loadStats(),
    );
    _unsubscribeLiveUpdates.add(
      realtime.onLiveUpdate('price-offers', (_) => _loadStats()),
    );
    _unsubscribeLiveUpdates.add(
      realtime.onLiveUpdate('quotations', (_) => _loadStats()),
    );
  }

  @override
  void dispose() {
    _statsPollTimer?.cancel();
    for (final unsubscribe in _unsubscribeLiveUpdates) {
      unsubscribe();
    }
    super.dispose();
  }

  /// There's no backend stats endpoint, so this counts client-side off the
  /// same list calls the other screens already make — capped by a generous
  /// per_page rather than the default 50, since exact totals aren't critical
  /// for a quick-glance dashboard tile.
  Future<void> _loadStats() async {
    // Only show the spinner for the very first load — background refreshes
    // (realtime pings, poll, returning from another screen) should swap the
    // numbers in place without flashing back to a loading state.
    if (_openRequests == null &&
        _pendingQuotations == null &&
        _draftPriceOffers == null) {
      setState(() => _statsLoading = true);
    }
    try {
      final requestsFuture = context.read<OffersService>().listRequests(
        page: 1,
        perPage: 100,
      );
      final quotationsFuture = context.read<QuotationsService>().listQuotations(
        page: 1,
        perPage: 100,
      );
      final requests = await requestsFuture;
      final quotations = await quotationsFuture;
      if (!mounted) return;
      setState(() {
        _openRequests = requests.where((r) => r.status == 'IN_APPROVAL').length;
        _pendingQuotations = quotations
            .where((q) => q.status == 'DRAFT' || q.status == 'SENT')
            .length;
        _draftPriceOffers = requests.where((r) => r.status == 'DRAFT').length;
        _statsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      heroPageRoute((_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _push(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // Whatever the pushed screen was (create offer, price offers, quotations,
    // sales orders...) may have changed the underlying counts, and this same
    // HomeScreen instance never left the tree, so its stats need a manual
    // re-fetch on return.
    if (mounted) _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: const Hero(
              tag: 'app-icon',
              child: Image(image: AssetImage('assets/app_icon.png')),
            ),
          ),
        ),
        title: Text(l10n.commonAppName),
        actions: [
          const ConnectionStatusBadge(),
          const LanguageToggle(),
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.homeSignOutTooltip,
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: AppRefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            if (user != null)
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      initialsFor(user.name),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greetingForHour(l10n, DateTime.now().hour),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const OfflineSyncStatusButton(),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: QuickStatTile(
                      icon: Icons.request_quote_outlined,
                      color: theme.colorScheme.primary,
                      count: _openRequests,
                      loading: _statsLoading,
                      label: l10n.homeStatsOpenRequestsLabel,
                      onTap: () => _push(context, const PriceOffersScreen(initialStatusKey: 'OPEN_REQUESTS')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: QuickStatTile(
                      icon: Icons.description_outlined,
                      color: const Color(0xFF0E9488),
                      count: _pendingQuotations,
                      loading: _statsLoading,
                      label: l10n.homeStatsPendingQuotationsLabel,
                      onTap: () => _push(context, const QuotationsScreen()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: QuickStatTile(
                      icon: Icons.edit_note_outlined,
                      color: const Color(0xFFD97706),
                      count: _draftPriceOffers,
                      loading: _statsLoading,
                      label: l10n.homeStatsDraftPriceOffersLabel,
                      onTap: () => _push(context, const PriceOffersScreen(initialStatusKey: 'DRAFT')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PremiumMenuCard(
              title: l10n.homePriceOfferTitle,
              subtitle: l10n.homePriceOfferSubtitle,
              icon: Icons.request_quote_outlined,
              color: theme.colorScheme.primary,
              actions: [
                MenuAction(
                  label: l10n.homeCreateOfferAction,
                  icon: Icons.add_circle_outline,
                  onTap: () => _push(context, const CreateOfferScreen()),
                ),
                MenuAction(
                  label: l10n.homePriceOffersAction,
                  icon: Icons.list_alt_outlined,
                  onTap: () => _push(context, const PriceOffersScreen()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PremiumMenuCard(
              title: l10n.homeQuotationTitle,
              subtitle: l10n.homeQuotationSubtitle,
              icon: Icons.description_outlined,
              color: const Color(0xFF0E9488),
              actions: [
                MenuAction(
                  label: l10n.homeQuotationsAction,
                  icon: Icons.list_alt_outlined,
                  onTap: () => _push(context, const QuotationsScreen()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            PremiumMenuCard(
              title: l10n.homeSalesOrderTitle,
              subtitle: l10n.homeSalesOrderSubtitle,
              icon: Icons.local_shipping_outlined,
              color: const Color(0xFFD97706),
              actions: [
                MenuAction(
                  label: l10n.homeOrdersAction,
                  icon: Icons.list_alt_outlined,
                  onTap: () => _push(context, const SalesOrdersScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
