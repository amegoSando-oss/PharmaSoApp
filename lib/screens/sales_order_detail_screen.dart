import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/realtime_client.dart';
import '../models/sales_order.dart';
import '../services/auth_service.dart';
import '../services/reference_cache.dart';
import '../services/sales_orders_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/section_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_pill.dart';
import '../l10n/generated/app_localizations.dart';

class SalesOrderDetailScreen extends StatefulWidget {
  final int id;

  const SalesOrderDetailScreen({super.key, required this.id});

  @override
  State<SalesOrderDetailScreen> createState() => _SalesOrderDetailScreenState();
}

class _SalesOrderDetailScreenState extends State<SalesOrderDetailScreen> {
  late Future<SalesOrder> _future;
  bool _releasing = false;
  String? _actionError;
  bool _flash = false;

  Timer? _flashTimer;
  VoidCallback? _unsubscribeLiveUpdate;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    // Real-time: if this exact order changes (e.g. a hold gets released from
    // another device), silently refetch and briefly flash — same channel +
    // per-id matching OrdersView.js uses for its open detail modal.
    _unsubscribeLiveUpdate = context.read<RealtimeClient>().onLiveUpdate('sales-orders', (payload) {
      if (payload['order_id']?.toString() != widget.id.toString()) return;
      _reload();
      _triggerFlash();
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _unsubscribeLiveUpdate?.call();
    super.dispose();
  }

  Future<SalesOrder> _fetch() => context.read<SalesOrdersService>().getOrder(widget.id);

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<void> _pullRefresh() async {
    _reload();
    try {
      await _future;
    } catch (_) {
      // AppRefreshIndicator just needs the Future to complete either way —
      // the FutureBuilder below owns rendering the error state.
    }
  }

  void _triggerFlash() {
    _flashTimer?.cancel();
    setState(() => _flash = true);
    _flashTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  Future<void> _releaseHold() async {
    setState(() {
      _releasing = true;
      _actionError = null;
    });
    try {
      await context.read<SalesOrdersService>().releaseHold(widget.id, reason: 'Credit approved manually');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.salesOrderDetailHoldReleasedMessage)));
      }
      _reload();
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() => _actionError = l10n.salesOrderDetailReleaseHoldError);
    } finally {
      if (mounted) setState(() => _releasing = false);
    }
  }

  String _warehouseName(int? id, AuthService auth, AppLocalizations l10n) {
    if (id == null) return '—';
    for (final w in auth.currentUser?.warehouses ?? const []) {
      if (w.id == id) return w.name;
    }
    return l10n.salesOrderDetailWarehouseFallback(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.salesOrderDetailTitle)),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _flash ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
        child: FutureBuilder<SalesOrder>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonDetail();
          }
          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : l10n.salesOrderDetailLoadError;
            return ErrorState(message: message, onRetry: _reload);
          }
          return _buildDetail(context, snapshot.data!);
        },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, SalesOrder order) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final reference = context.watch<ReferenceCache>();
    final auth = context.watch<AuthService>();

    return AppRefreshIndicator(
      onRefresh: _pullRefresh,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(order.orderNumber, style: theme.textTheme.titleLarge)),
            StatusPill(value: order.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: l10n.salesOrderDetailSummaryTitle,
          child: Column(
            children: [
              _kvRow(l10n.salesOrderDetailCustomerLabel, Text(order.customerName ?? reference.customerName(order.customerId))),
              _kvRow(l10n.salesOrderDetailWarehouseLabel, Text(_warehouseName(order.warehouseId, auth, l10n))),
              _kvRow(l10n.salesOrderDetailQuotationLabel, Text(order.quotationNumber ?? '—')),
              _kvRow(l10n.salesOrderDetailOrderDateLabel, Text(order.orderDate ?? '—')),
              _kvRow(l10n.salesOrderDetailJdeOrderLabel, Text(order.jdeOrderNumber ?? '—')),
              _kvRow(l10n.salesOrderDetailCreditLabel, StatusPill(value: order.creditStatus, dense: true)),
              _kvRow(l10n.salesOrderDetailHoldLabel, StatusPill(value: order.hasActiveHold ? 'HOLD' : 'NONE', dense: true), isLast: true),
            ],
          ),
        ),
        if (order.parentSalesOrderId != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.salesOrderDetailSplitOriginTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.salesOrderDetailSplitOriginMessage(
                    order.splitSequence.toString(),
                    order.parentOrder?.orderNumber ?? '#${order.parentSalesOrderId}',
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SalesOrderDetailScreen(id: order.parentSalesOrderId!)),
                  ),
                  icon: const Icon(Icons.call_made, size: 16),
                  label: Text(l10n.salesOrderDetailViewOriginalOrderLabel),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l10n.salesOrderDetailLinesTitle,
          child: order.lines.isEmpty
              ? Text(l10n.salesOrderDetailNoLinesMessage)
              : Column(
                  children: [
                    for (final line in order.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.itemName ?? l10n.salesOrderDetailItemFallback(line.itemId.toString()),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${l10n.salesOrderDetailQtyLabel(line.quantity.toString(), line.uom ?? '')}'
                              '${(line.focQuantity ?? 0) > 0 ? ' · ${l10n.salesOrderDetailFocLabel(line.focQuantity.toString())}' : ''}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                            Text(
                              '${l10n.salesOrderDetailUnitPriceBeforeTax((line.priceBeforeTax ?? line.price).toStringAsFixed(2))}'
                              ' · ${line.includeTax ? l10n.salesOrderDetailTaxRateLabel((line.taxRate ?? 0).toString()) : l10n.salesOrderDetailNoTaxLabel}'
                              ' · ${l10n.salesOrderDetailUnitPriceAfterTax((line.priceAfterTax ?? line.price).toStringAsFixed(2))}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                            ),
                            Text(
                              l10n.salesOrderDetailLineTotalLabel(line.lineTotal.toStringAsFixed(2)),
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.salesOrderDetailOrderTotalLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(order.orderTotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
        ),
        if (order.holds.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.salesOrderDetailHoldsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final hold in order.holds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hold.holdType ?? l10n.salesOrderDetailHoldTypeFallback, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (hold.reason != null) Text(hold.reason!, style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        StatusPill(value: hold.status, dense: true),
                      ],
                    ),
                  ),
                if (_actionError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  InlineErrorBanner(message: _actionError!),
                ],
                if (order.holdStatus == 'ACTIVE') ...[
                  const SizedBox(height: AppSpacing.sm),
                  LoadingButton(label: l10n.salesOrderDetailReleaseHoldLabel, loading: _releasing, onPressed: _releaseHold),
                ],
              ],
            ),
          ),
        ],
      ],
      ),
    );
  }

  Widget _kvRow(String label, Widget value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: value)),
        ],
      ),
    );
  }
}
