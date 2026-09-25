import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import '../core/api_client.dart';
import '../core/realtime_client.dart';
import '../core/text_utils.dart';
import '../models/customer.dart';
import '../models/sales_order.dart';
import '../services/reference_cache.dart';
import '../services/sales_orders_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/notification_bell.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_pill.dart';
import '../l10n/generated/app_localizations.dart';
import 'sales_order_detail_screen.dart';

class SalesOrdersScreen extends StatefulWidget {
  const SalesOrdersScreen({super.key});

  @override
  State<SalesOrdersScreen> createState() => _SalesOrdersScreenState();
}

class _SalesOrdersScreenState extends State<SalesOrdersScreen> {
  late Future<List<SalesOrder>> _future;
  bool _firstLoad = true;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  int? _selectedCustomerId;
  String? _busyReleaseOrderId;

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
    // Real-time: silently refetch on every "sales-orders" ping (same channel
    // OrdersView.js subscribes to); a 90s poll covers Reverb not running.
    _pollTimer = Timer.periodic(const Duration(seconds: 90), (_) => _refresh());
    _unsubscribeLiveUpdate = context.read<RealtimeClient>().onLiveUpdate('sales-orders', (_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollTimer?.cancel();
    _unsubscribeLiveUpdate?.call();
    super.dispose();
  }

  Future<List<SalesOrder>> _load() {
    return context.read<SalesOrdersService>().listOrders();
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

  List<SalesOrder> _applyFilters(List<SalesOrder> rows, ReferenceCache reference) {
    return rows.where((row) {
      if (_searchQuery.isNotEmpty) {
        final haystack = '${row.orderNumber} ${row.customerName ?? reference.customerName(row.customerId)}'.toLowerCase();
        if (!haystack.contains(_searchQuery)) return false;
      }
      if (_selectedDate != null) {
        final orderDate = DateTime.tryParse(row.orderDate ?? '');
        if (orderDate == null) return false;
        if (orderDate.year != _selectedDate!.year || orderDate.month != _selectedDate!.month || orderDate.day != _selectedDate!.day) {
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

  Future<void> _releaseHold(SalesOrder order) async {
    setState(() => _busyReleaseOrderId = order.id.toString());
    try {
      await context.read<SalesOrdersService>().releaseHold(order.id, reason: 'Credit approved manually');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.salesOrdersHoldReleasedMessage)));
      }
      _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.salesOrdersReleaseHoldError)));
      }
    } finally {
      if (mounted) setState(() => _busyReleaseOrderId = null);
    }
  }

  Future<void> _openDetail(SalesOrder row) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SalesOrderDetailScreen(id: row.id)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = context.watch<ReferenceCache>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesOrdersTitle), actions: const [NotificationBell()]),
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
                          hintText: l10n.salesOrdersSearchHint,
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
                        label: Text(l10n.salesOrdersClearFilters),
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
              child: FutureBuilder<List<SalesOrder>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _firstLoad) {
                    return const SkeletonRequestList();
                  }
                  if (snapshot.hasError) {
                    final message = snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : l10n.salesOrdersLoadError;
                    return ListView(children: [const SizedBox(height: 40), ErrorState(message: message, onRetry: _refresh)]);
                  }
                  final allRows = snapshot.data ?? const [];
                  if (allRows.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.local_shipping_outlined,
                          title: l10n.salesOrdersEmptyTitle,
                          message: l10n.salesOrdersEmptyMessage,
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
                          title: l10n.salesOrdersNoMatchTitle,
                          message: l10n.salesOrdersNoMatchMessage,
                          actionLabel: l10n.salesOrdersClearFilters,
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
                      final releasing = _busyReleaseOrderId == row.id.toString();
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openDetail(row),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(row.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(
                                            row.customerName ?? reference.customerName(row.customerId),
                                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    StatusPill(value: row.creditStatus, dense: true),
                                    StatusPill(value: row.hasActiveHold ? 'HOLD' : 'NONE', dense: true),
                                    StatusPill(value: row.status, dense: true),
                                  ],
                                ),
                                if (row.holdStatus == 'ACTIVE') ...[
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: releasing ? null : () => _releaseHold(row),
                                      icon: releasing
                                          ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.lock_open_outlined, size: 16),
                                      label: Text(releasing ? l10n.salesOrdersReleasingLabel : l10n.salesOrdersReleaseHoldLabel),
                                    ),
                                  ),
                                ],
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
            Text(l10n.salesOrdersFilterByCustomerTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.salesOrdersSearchCustomersHint, prefixIcon: const Icon(Icons.search)),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: Text(l10n.salesOrdersNoMatchingCustomers)),
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
