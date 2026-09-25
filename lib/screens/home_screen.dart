import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/hero_page_route.dart';
import '../core/text_utils.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/language_toggle.dart';
import '../widgets/notification_bell.dart';
import '../widgets/premium_menu_card.dart';
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

/// The app's hub: a greeting header and three dropdown menus (Price Offer /
/// Quotation / Sales Order) that navigate to their own dedicated screens —
/// see price_offers_screen.dart, quotations_screen.dart, sales_orders_screen.dart.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      heroPageRoute((_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
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
          IconButton(icon: const Icon(Icons.logout), tooltip: l10n.homeSignOutTooltip, onPressed: () => _logout(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        children: [
          if (user != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    initialsFor(user.name),
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greetingForHour(l10n, DateTime.now().hour),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                      Text(
                        user.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (user.roleNames.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.roleNames.first,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
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
    );
  }
}
