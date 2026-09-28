import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import '../core/api_client.dart';
import '../core/realtime_client.dart';
import '../core/text_utils.dart';
import '../models/customer.dart';
import '../models/quotation.dart';
import '../services/quotations_service.dart';
import '../services/reference_cache.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/notification_bell.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_pill.dart';
import '../l10n/generated/app_localizations.dart';
import 'quotation_detail_screen.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  late Future<List<Quotation>> _future;
  bool _firstLoad = true;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  int? _selectedCustomerId;

  Timer? _pollTimer;
  VoidCallback? _unsubscribeLiveUpdate;

  @override
  void initState() {
    super.initState();
    _future = _load()..whenComplete(() {
      if (mounted) setState(() => _firstLoad = false);
    });
    context.read<ReferenceCache>().ensureLoaded();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    // Real-time: silently refetch on every "quotations" ping (same channel
    // QuotationsView.js subscribes to); a 90s poll covers Reverb not running.
    _pollTimer = Timer.periodic(const Duration(seconds: 90), (_) => _refresh());
    _unsubscribeLiveUpdate = context.read<RealtimeClient>().onLiveUpdate('quotations', (_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollTimer?.cancel();
    _unsubscribeLiveUpdate?.call();
    super.dispose();
  }

  Future<List<Quotation>> _load() {
    return context.read<QuotationsService>().listQuotations();
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // FutureBuilder below owns error rendering.
    } finally {
      if (mounted) setState(() => _firstLoad = false);
    }
  }

  List<Quotation> _applyFilters(List<Quotation> rows, ReferenceCache reference) {
    return rows.where((row) {
      if (_searchQuery.isNotEmpty) {
        final haystack = '${row.quotationNumber} ${reference.customerName(row.customerId)}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      if (_selectedDate != null) {
        final issued = DateTime.tryParse(row.quotationDate ?? '');
        if (issued == null) return false;
        if (issued.year != _selectedDate!.year || issued.month != _selectedDate!.month || issued.day != _selectedDate!.day) {
          return false;
        }
      }
      if (_selectedCustomerId != null && row.customerId != _selectedCustomerId) return false;
      return true;
    }).toList();
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
      builder: (context) => _CustomerPicker(customers: customers),
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

  Future<void> _openDetail(Quotation quotation) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: quotation)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = context.watch<ReferenceCache>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quotationsTitle),
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
                          hintText: l10n.quotationsSearchHint,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(icon: const Icon(Icons.close, size: 18), onPressed: _searchController.clear),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _IconFilterButton(icon: Icons.calendar_today_outlined, active: _selectedDate != null, onTap: _pickDate),
                    const SizedBox(width: AppSpacing.sm),
                    _IconFilterButton(icon: Icons.storefront_outlined, active: _selectedCustomerId != null, onTap: _pickCustomer),
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
                        label: Text(l10n.quotationsClearFilters),
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
              child: FutureBuilder<List<Quotation>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _firstLoad) {
                    return const SkeletonRequestList();
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : l10n.quotationsLoadError;
                    return ListView(children: [const SizedBox(height: 40), ErrorState(message: message, onRetry: _refresh)]);
                  }
                  final allRows = snapshot.data ?? const [];
                  if (allRows.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.description_outlined,
                          title: l10n.quotationsEmptyTitle,
                          message: l10n.quotationsEmptyMessage,
                        ),
                      ],
                    );
                  }
                  final rows = _applyFilters(allRows, reference);
                  if (rows.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.search_off,
                          title: l10n.quotationsNoMatchTitle,
                          message: l10n.quotationsNoMatchMessage,
                          actionLabel: l10n.quotationsClearFilters,
                          actionIcon: Icons.filter_alt_off_outlined,
                          onAction: _clearFilters,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openDetail(row),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(row.quotationNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                        reference.customerName(row.customerId),
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.quotationsVersionValidUntil('${row.version}', row.validUntil ?? '—'),
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 11),
                                      ),
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconFilterButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _IconFilterButton({required this.icon, required this.active, required this.onTap});

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

class _CustomerPicker extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerPicker({required this.customers});

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  String _query = '';

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
            Text(l10n.quotationsFilterByCustomerTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.quotationsSearchCustomersHint, prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: Text(l10n.quotationsNoMatchingCustomers)),
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
