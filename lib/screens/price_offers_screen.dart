import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import '../core/api_client.dart';
import '../core/realtime_client.dart';
import '../core/text_utils.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/customer.dart';
import '../models/price_offer_request.dart';
import '../services/offers_service.dart';
import '../services/reference_cache.dart';
import '../theme/app_spacing.dart';
import '../theme/status_style.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/notification_bell.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_filter_bar.dart';
import '../widgets/status_pill.dart';
import 'create_offer_screen.dart';
import 'request_detail_screen.dart';

class PriceOffersScreen extends StatefulWidget {
  final String? initialStatusKey;

  const PriceOffersScreen({super.key, this.initialStatusKey});

  @override
  State<PriceOffersScreen> createState() => _PriceOffersScreenState();
}

class _PriceOffersScreenState extends State<PriceOffersScreen> {
  late Future<List<PriceOfferRequestSummary>> _future;
  bool _firstLoad = true;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  int? _selectedCustomerId;
  late String? _selectedStatusKey;

  Timer? _pollTimer;
  VoidCallback? _unsubscribeLiveUpdate;

  @override
  void initState() {
    super.initState();
    _selectedStatusKey = widget.initialStatusKey;
    _future = _load()..whenComplete(() {
      if (mounted) setState(() => _firstLoad = false);
    });
    context.read<ReferenceCache>().ensureLoaded();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    // Real-time: silently refetch on every "price-offers" ping, same channel
    // web's PriceOffersView.js subscribes to; a 90s poll covers the case
    // where Reverb isn't running (see docs/business-logic.md §12a).
    _pollTimer = Timer.periodic(const Duration(seconds: 90), (_) => _refresh());
    _unsubscribeLiveUpdate = context.read<RealtimeClient>().onLiveUpdate('price-offers', (_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollTimer?.cancel();
    _unsubscribeLiveUpdate?.call();
    super.dispose();
  }

  Future<List<PriceOfferRequestSummary>> _load() {
    return context.read<OffersService>().listRequests();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // Swallow here — the FutureBuilder below owns rendering the error state.
    } finally {
      if (mounted) setState(() => _firstLoad = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateOfferScreen()),
    );
    if (created == true) _refresh();
  }

  Future<void> _openDetail(PriceOfferRequestSummary row) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RequestDetailScreen(id: row.id)),
    );
    _refresh();
  }

  /// Long-press quick action on a DRAFT card — skips the trip into the
  /// detail screen just to hit "Submit for approval". If the backend
  /// rejects it (e.g. the request isn't actually submit-eligible), the
  /// sheet surfaces that error inline instead of failing silently.
  Future<void> _quickSubmit(PriceOfferRequestSummary row) async {
    HapticFeedback.mediumImpact();
    final reference = context.read<ReferenceCache>();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickSubmitSheet(
        row: row,
        customerName: reference.customerName(row.customerId),
      ),
    );
    if (submitted == true) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.priceOffersSubmittedSnackbar(row.requestNumber))),
        );
      }
      _refresh();
    }
  }

  List<PriceOfferRequestSummary> _applyNonStatusFilters(List<PriceOfferRequestSummary> rows, ReferenceCache reference) {
    return rows.where((row) {
      if (_searchQuery.isNotEmpty) {
        final haystack = '${row.requestNumber} ${reference.customerName(row.customerId)}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      if (_selectedDate != null) {
        final submitted = DateTime.tryParse(row.submittedAt ?? '');
        if (submitted == null) return false;
        if (submitted.year != _selectedDate!.year ||
            submitted.month != _selectedDate!.month ||
            submitted.day != _selectedDate!.day) {
          return false;
        }
      }
      if (_selectedCustomerId != null && row.customerId != _selectedCustomerId) return false;
      return true;
    }).toList();
  }

  List<PriceOfferRequestSummary> _applyStatusFilter(String? key, List<PriceOfferRequestSummary> rows) {
    switch (key) {
      case 'DRAFT':
        return rows.where((r) => r.status == 'DRAFT').toList();
      case 'PENDING':
        return rows.where((r) => r.isPendingFirstApproval).toList();
      case 'IN_APPROVAL':
        return rows.where((r) => r.isFurtherInApproval).toList();
      case 'REJECTED':
        return rows.where((r) => r.status == 'REJECTED').toList();
      case 'QUOTATION_GENERATED':
        return rows.where((r) => r.status == 'QUOTATION_GENERATED').toList();
      default:
        return rows;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickCustomer() async {
    final customers = context.read<ReferenceCache>().customers;
    final picked = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CustomerPickerSheet(customers: customers),
    );
    if (picked != null) setState(() => _selectedCustomerId = picked.id);
  }

  bool get _hasActiveFilters => _searchQuery.isNotEmpty || _selectedDate != null || _selectedCustomerId != null;

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _selectedDate = null;
      _selectedCustomerId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final reference = context.watch<ReferenceCache>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.priceOffersTitle),
        actions: const [ConnectionStatusBadge(), NotificationBell()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.priceOffersSearchHint,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: _searchController.clear,
                                ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterIconButton(
                      icon: Icons.calendar_today_outlined,
                      active: _selectedDate != null,
                      onTap: _pickDate,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _FilterIconButton(
                      icon: Icons.storefront_outlined,
                      active: _selectedCustomerId != null,
                      onTap: _pickCustomer,
                    ),
                  ],
                ),
                if (_hasActiveFilters) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (_selectedDate != null)
                        InputChip(
                          avatar: const Icon(Icons.event, size: 16),
                          label: Text(formatShortDate(_selectedDate!)),
                          onDeleted: () => setState(() => _selectedDate = null),
                        ),
                      if (_selectedCustomerId != null)
                        InputChip(
                          avatar: const Icon(Icons.storefront_outlined, size: 16),
                          label: Text(reference.customerName(_selectedCustomerId!)),
                          onDeleted: () => setState(() => _selectedCustomerId = null),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.filter_alt_off_outlined, size: 16),
                        label: Text(l10n.priceOffersClearFilters),
                        onPressed: _clearFilters,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<PriceOfferRequestSummary>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _firstLoad) {
                    return const SkeletonRequestList();
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : l10n.priceOffersLoadError;
                    return ListView(
                      children: [
                        const SizedBox(height: 40),
                        ErrorState(message: message, onRetry: _refresh),
                      ],
                    );
                  }
                  final allRows = snapshot.data ?? const [];
                  if (allRows.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: l10n.priceOffersEmptyTitle,
                          message: l10n.priceOffersEmptyMessage,
                          actionLabel: l10n.priceOffersNewRequest,
                          onAction: _openCreate,
                        ),
                      ],
                    );
                  }

                  final nonStatusFiltered = _applyNonStatusFilters(allRows, reference);
                  final statusOptions = [
                    StatusFilterOption(
                      key: null,
                      label: l10n.priceOffersStatusAll,
                      icon: Icons.apps,
                      color: theme.colorScheme.primary,
                      count: nonStatusFiltered.length,
                    ),
                    StatusFilterOption(
                      key: 'DRAFT',
                      label: l10n.priceOffersStatusDraft,
                      icon: statusStyleFor(context, 'DRAFT').icon,
                      color: statusStyleFor(context, 'DRAFT').color,
                      count: _applyStatusFilter('DRAFT', nonStatusFiltered).length,
                    ),
                    StatusFilterOption(
                      key: 'PENDING',
                      label: l10n.priceOffersStatusPending,
                      icon: Icons.hourglass_empty,
                      color: statusStyleFor(context, 'PENDING').color,
                      count: _applyStatusFilter('PENDING', nonStatusFiltered).length,
                    ),
                    StatusFilterOption(
                      key: 'IN_APPROVAL',
                      label: l10n.priceOffersStatusInApproval,
                      icon: statusStyleFor(context, 'IN_APPROVAL').icon,
                      color: statusStyleFor(context, 'IN_APPROVAL').color,
                      count: _applyStatusFilter('IN_APPROVAL', nonStatusFiltered).length,
                    ),
                    StatusFilterOption(
                      key: 'REJECTED',
                      label: l10n.priceOffersStatusRejected,
                      icon: statusStyleFor(context, 'REJECTED').icon,
                      color: statusStyleFor(context, 'REJECTED').color,
                      count: _applyStatusFilter('REJECTED', nonStatusFiltered).length,
                    ),
                    StatusFilterOption(
                      key: 'QUOTATION_GENERATED',
                      label: l10n.priceOffersStatusQuotationGenerated,
                      icon: Icons.description_outlined,
                      color: statusStyleFor(context, 'QUOTATION_GENERATED').color,
                      count: _applyStatusFilter('QUOTATION_GENERATED', nonStatusFiltered).length,
                    ),
                  ];
                  final rows = _applyStatusFilter(_selectedStatusKey, nonStatusFiltered);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: StatusFilterBar(
                          options: statusOptions,
                          selectedKey: _selectedStatusKey,
                          onSelected: (key) => setState(() => _selectedStatusKey = key),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: rows.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 60),
                                  EmptyState(
                                    icon: Icons.search_off,
                                    title: l10n.priceOffersNoMatchTitle,
                                    message: l10n.priceOffersNoMatchMessage,
                                    actionLabel: l10n.priceOffersClearFilters,
                                    actionIcon: Icons.filter_alt_off_outlined,
                                    onAction: () {
                                      _clearFilters();
                                      setState(() => _selectedStatusKey = null);
                                    },
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                                itemCount: rows.length,
                                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final row = rows[index];
                                  final statusColor = statusStyleFor(context, row.status).color;
                                  final isDraft = row.status == 'DRAFT';
                                  return Card(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => _openDetail(row),
                                      onLongPress: isDraft ? () => _quickSubmit(row) : null,
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(row.requestNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    reference.customerName(row.customerId),
                                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                                  ),
                                                  if (isDraft) ...[
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.bolt, size: 12, color: theme.colorScheme.primary),
                                                        const SizedBox(width: 2),
                                                        Text(
                                                          l10n.priceOffersHoldToSubmit,
                                                          style: theme.textTheme.labelSmall?.copyWith(
                                                            color: theme.colorScheme.primary,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            StatusPill(value: row.status),
                                            const SizedBox(width: 4),
                                            Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: Text(l10n.priceOffersNewRequest),
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterIconButton({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Icon(icon, size: 18, color: active ? theme.colorScheme.onPrimary : theme.colorScheme.outline),
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerPickerSheet({required this.customers});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final filtered = _query.isEmpty
        ? widget.customers
        : widget.customers.where((c) => c.name.toLowerCase().contains(_query)).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.priceOffersFilterByCustomer, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.priceOffersSearchCustomersHint, prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: Text(l10n.priceOffersNoMatchingCustomers)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final customer = filtered[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.storefront_outlined),
                          title: Text(customer.name),
                          onTap: () => Navigator.of(context).pop(customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick-submit confirmation sheet for a long-pressed DRAFT card — the
/// mobile-friendly equivalent of an AlertDialog, styled to match the rest
/// of the app's rounded bottom sheets (notification panel, customer picker).
class _QuickSubmitSheet extends StatefulWidget {
  final PriceOfferRequestSummary row;
  final String customerName;

  const _QuickSubmitSheet({required this.row, required this.customerName});

  @override
  State<_QuickSubmitSheet> createState() => _QuickSubmitSheetState();
}

class _QuickSubmitSheetState extends State<_QuickSubmitSheet> {
  bool _submitting = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await context.read<OffersService>().submitRequest(widget.row.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).priceOffersSubmitFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.priceOffersSubmitConfirmTitle, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.row.requestNumber} · ${widget.customerName}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.priceOffersSubmitConfirmBody,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              InlineErrorBanner(message: _error!),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                    child: Text(l10n.priceOffersNotNow),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: LoadingButton(
                    label: l10n.priceOffersSubmitButton,
                    icon: Icons.send_rounded,
                    loading: _submitting,
                    onPressed: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
