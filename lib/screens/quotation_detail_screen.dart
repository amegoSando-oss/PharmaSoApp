import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/quotation.dart';
import '../models/warehouse.dart';
import '../models/warehouse_item_stock.dart';
import '../services/auth_service.dart';
import '../services/offers_service.dart';
import '../services/quotations_service.dart';
import '../services/reference_cache.dart';
import '../theme/app_spacing.dart';
import '../utils/related_records_nav.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/connection_status_badge.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/notification_bell.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import '../l10n/generated/app_localizations.dart';
import 'request_detail_screen.dart';

/// One warehouse row of a line being released — a line starts with a single
/// row (defaulting to its full remaining quantity), but the rep can add
/// more when a single warehouse doesn't hold enough of the item; each row
/// becomes its own split in the request (see OrderReleaseSplit).
class _SplitRow {
  int? warehouseId;
  final TextEditingController qtyController;

  _SplitRow({this.warehouseId, num? initialQuantity})
      : qtyController = TextEditingController(
          text: (initialQuantity != null && initialQuantity > 0) ? '$initialQuantity' : '',
        );

  num get quantity => num.tryParse(qtyController.text) ?? 0;

  void dispose() => qtyController.dispose();
}

/// There's no dedicated single-quotation GET endpoint — the web app itself
/// reuses the list row as detail data (QuotationsView.js:61-65), so this
/// screen is handed the [Quotation] object directly instead of fetching it.
class QuotationDetailScreen extends StatefulWidget {
  final Quotation quotation;

  const QuotationDetailScreen({super.key, required this.quotation});

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  late Quotation _quotation;
  String? _busyAction;
  String? _actionError;
  bool _pdfBusy = false;

  bool _settingsLoading = true;
  bool _partialReleaseEnabled = false;
  final Map<int, List<_SplitRow>> _lineSplits = {};
  final Map<int, List<WarehouseItemStock>> _stockByItem = {};
  final Set<int> _stockLoadingItemIds = {};

  String _responseValue = 'ACCEPTED';
  final _responseCustomerNameController = TextEditingController();
  final _responseCommentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quotation = widget.quotation;
    _loadReleaseSettings();
    final releasableLines = _quotation.currentVersion?.releasableLines ?? const [];
    if (releasableLines.isNotEmpty) _loadWarehouseStock(releasableLines);
  }

  /// Same "no GET-by-id" limitation as everywhere else that opens a
  /// quotation — a pull-to-refresh has to re-resolve it by number.
  Future<void> _refresh() async {
    try {
      final updated = await context.read<QuotationsService>().findByNumber(
        _quotation.quotationNumber,
      );
      if (!mounted || updated == null) return;
      setState(() => _quotation = updated);
      final releasableLines = updated.currentVersion?.releasableLines ?? const [];
      if (releasableLines.isNotEmpty) _loadWarehouseStock(releasableLines);
    } catch (_) {
      // AppRefreshIndicator just needs the Future to complete either way.
    }
  }

  @override
  void dispose() {
    for (final rows in _lineSplits.values) {
      for (final row in rows) {
        row.dispose();
      }
    }
    _responseCustomerNameController.dispose();
    _responseCommentsController.dispose();
    super.dispose();
  }

  /// One fetch per item (not per warehouse) — mirrors QuotationsView.js's
  /// loadOrderStock, just split into per-item calls (see
  /// OffersService.fetchWarehouseStockForItem's own doc comment). A missing
  /// entry afterward just means the warehouse dropdown won't show an
  /// "Available" hint for that item; it never blocks anything by itself —
  /// _checkWarehouseAvailability re-fetches fresh right before submit.
  Future<void> _loadWarehouseStock(List<QuotationLine> releasableLines) async {
    final offers = context.read<OffersService>();
    for (final line in releasableLines) {
      if (_stockByItem.containsKey(line.itemId) || _stockLoadingItemIds.contains(line.itemId)) continue;
      _stockLoadingItemIds.add(line.itemId);
      try {
        final stocks = await offers.fetchWarehouseStockForItem(line.itemId);
        if (!mounted) return;
        setState(() => _stockByItem[line.itemId] = stocks);
      } catch (_) {
        // Leave unset — no "Available" hint for this item, nothing more.
      } finally {
        _stockLoadingItemIds.remove(line.itemId);
      }
    }
  }

  /// Bypasses _loadWarehouseStock's "already fetched" guard — the rep taps
  /// this right before picking a warehouse to be sure the figures reflect
  /// whatever's changed since the screen opened (JDE availability moves
  /// with every other release/order, not just this one).
  Future<void> _refreshWarehouseStock(QuotationLine line) async {
    if (_stockLoadingItemIds.contains(line.itemId)) return;
    setState(() => _stockLoadingItemIds.add(line.itemId));
    try {
      final stocks = await context.read<OffersService>().fetchWarehouseStockForItem(line.itemId);
      if (!mounted) return;
      setState(() => _stockByItem[line.itemId] = stocks);
    } catch (_) {
      // Leave whatever was already there — nothing more to update.
    } finally {
      if (mounted) setState(() => _stockLoadingItemIds.remove(line.itemId));
    }
  }

  Future<void> _loadReleaseSettings() async {
    final canRelease = [
      'ACCEPTED',
      'PARTIALLY_CONVERTED',
    ].contains(widget.quotation.status);
    if (!canRelease) {
      setState(() => _settingsLoading = false);
      return;
    }
    try {
      final enabled = await context
          .read<OffersService>()
          .fetchPartialReleaseEnabled();
      if (!mounted) return;
      setState(() {
        _partialReleaseEnabled = enabled;
        _settingsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _settingsLoading = false);
    }
  }

  /// Lazily creates a line's split-row list the first time it's rendered —
  /// a single row to start, defaulting its quantity to the full remaining
  /// amount, matching QuotationsView.js's getSplits().
  List<_SplitRow> _splitsFor(QuotationLine line) {
    return _lineSplits.putIfAbsent(
      line.id,
      () => [_SplitRow(initialQuantity: line.remainingQuantity)],
    );
  }

  void _addSplitRow(QuotationLine line) {
    setState(() => _splitsFor(line).add(_SplitRow()));
  }

  void _removeSplitRow(QuotationLine line, int index) {
    setState(() => _splitsFor(line).removeAt(index).dispose());
  }

  num _allocatedQuantity(QuotationLine line) {
    return _splitsFor(line).fold<num>(0, (sum, row) => sum + row.quantity);
  }

  /// A touched line (at least one split with both a warehouse and a
  /// positive quantity) is only valid once its splits add up to exactly
  /// its full remaining quantity — under-allocated (some of the line left
  /// unaccounted for) is just as invalid as over-allocated, regardless of
  /// the partial-release setting. Partial release still means "skip this
  /// line entirely, release others" (an untouched line is simply excluded
  /// from submission), not "release less than the line's own quantity".
  bool _lineIsValid(QuotationLine line) {
    final validSplits = _splitsFor(line).where((row) => row.warehouseId != null && row.quantity > 0);
    if (validSplits.isEmpty) return false;
    final total = validSplits.fold<num>(0, (sum, row) => sum + row.quantity);
    return (total - line.remainingQuantity).abs() <= 0.001;
  }

  /// Resets every releasable line back to a single row at its full
  /// remaining amount, keeping whatever warehouse was already chosen on
  /// its first row — the "release the whole quotation" button.
  void _fillFullRemaining(List<QuotationLine> releasableLines) {
    setState(() {
      for (final line in releasableLines) {
        final rows = _lineSplits[line.id];
        final existingWarehouse = (rows != null && rows.isNotEmpty) ? rows.first.warehouseId : null;
        rows?.forEach((row) => row.dispose());
        _lineSplits[line.id] = [
          _SplitRow(warehouseId: existingWarehouse, initialQuantity: line.remainingQuantity),
        ];
      }
    });
  }

  bool _canSubmitRelease(List<QuotationLine> releasableLines) {
    if (releasableLines.isEmpty) return false;
    if (!_partialReleaseEnabled) {
      return releasableLines.every(_lineIsValid);
    }
    return releasableLines.any(_lineIsValid);
  }

  Future<void> _submitRelease(List<QuotationLine> releasableLines) async {
    final lines = <OrderReleaseLine>[];
    final linesById = <int, QuotationLine>{};
    for (final line in releasableLines) {
      final splits = _splitsFor(line)
          .where((row) => row.warehouseId != null && row.quantity > 0)
          .map((row) => OrderReleaseSplit(warehouseId: row.warehouseId!, quantity: row.quantity))
          .toList();
      if (splits.isEmpty) continue;
      lines.add(OrderReleaseLine(lineId: line.id, splits: splits));
      linesById[line.id] = line;
    }
    if (lines.isEmpty) return;

    // A warning, not a hard block — see _showInsufficientStockDialog's own
    // doc comment for why letting the rep proceed anyway is safe.
    final shortages = await _checkWarehouseAvailability(lines, linesById);
    if (shortages == null) return; // the availability check itself failed; error already shown
    if (shortages.isNotEmpty) {
      if (!mounted) return;
      final proceedAnyway = await _showInsufficientStockDialog(shortages);
      if (!proceedAnyway) return;
    }

    await _performAction(
      'order',
      () => context.read<OffersService>().createOrder(
        widget.quotation.id,
        lines: lines,
      ),
    );
    if (mounted && _actionError == null) {
      Navigator.of(context).pop();
    }
  }

  /// Returns the list of human-readable shortage messages (empty = every
  /// selected warehouse can cover its line), or null if the availability
  /// lookup itself couldn't complete — in which case an error is already
  /// set and the caller should just abort rather than proceed blind.
  Future<List<String>?> _checkWarehouseAvailability(
    List<OrderReleaseLine> lines,
    Map<int, QuotationLine> linesById,
  ) async {
    final offers = context.read<OffersService>();
    final l10n = AppLocalizations.of(context);
    final shortages = <String>[];
    try {
      for (final releaseLine in lines) {
        final line = linesById[releaseLine.lineId];
        if (line == null) continue;
        final List<WarehouseItemStock> stocks = await offers.fetchWarehouseStockForItem(line.itemId);
        for (final split in releaseLine.splits) {
          final match = stocks.where((s) => s.warehouseId == split.warehouseId);
          final num available = match.isEmpty ? 0 : match.first.availableQty;
          if (split.quantity > available) {
            shortages.add(
              l10n.quotationDetailInsufficientStockLine(
                line.itemName ?? '#${line.itemId}',
                _formatQty(split.quantity),
                _formatQty(available),
                line.uom ?? '',
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _actionError = l10n.quotationDetailInsufficientStockCheckFailed);
      }
      return null;
    }
    return shortages;
  }

  String _formatQty(num value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  /// Every warehouse that stocks this item, not just the rep's assigned
  /// ones — matches the web release screen's stock table, shown as a row
  /// of small chips instead (a multi-column table doesn't fit phone width;
  /// same trade-off create_offer_screen's _WarehouseStockSection makes).
  /// The refresh button re-fetches on demand, bypassing the load-once
  /// cache, so the rep can pull the latest figure right before choosing a
  /// warehouse instead of trusting whatever was loaded when the screen
  /// first opened.
  Widget _buildWarehouseStockRow(ThemeData theme, AppLocalizations l10n, QuotationLine line) {
    final loading = _stockLoadingItemIds.contains(line.itemId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.quotationDetailWarehouseStockLabel,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 28,
              height: 28,
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      padding: EdgeInsets.zero,
                      tooltip: l10n.quotationDetailRefreshStockTooltip,
                      onPressed: () => _refreshWarehouseStock(line),
                    ),
            ),
          ],
        ),
        if (!loading) const SizedBox(height: AppSpacing.xs),
        if (!loading)
          if ((_stockByItem[line.itemId] ?? const []).isEmpty)
            Text(
              l10n.createOfferNoWarehouseStock,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.sm,
              children: [
                for (final stock in _stockByItem[line.itemId]!)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stock.warehouseName ?? l10n.createOfferWarehouseFallback(stock.warehouseId)}: '
                      '${l10n.createOfferAvailableLabel} ${_formatQty(stock.availableQty)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
      ],
    );
  }

  /// The known available quantity of [itemId] in [warehouseId], or null if
  /// stock for that item hasn't been fetched yet — null means "don't cap
  /// anything", not "zero available".
  num? _availableForWarehouse(int itemId, int warehouseId) {
    final stocks = _stockByItem[itemId];
    if (stocks == null) return null;
    final match = stocks.where((s) => s.warehouseId == warehouseId);
    return match.isEmpty ? null : match.first.availableQty;
  }

  /// Caps a split row at its chosen warehouse's own available quantity —
  /// once a row hits that ceiling, the rep can't type any more into it and
  /// has to add another split row for a different warehouse to cover the
  /// rest manually (see _addSplitRow / the "Split across another
  /// warehouse" button) — this only clamps the row itself, it never adds
  /// or fills another row on its own.
  void _clampSplitRowToAvailability(QuotationLine line, int rowIndex) {
    final row = _splitsFor(line)[rowIndex];
    final warehouseId = row.warehouseId;
    if (warehouseId == null) return;
    final available = _availableForWarehouse(line.itemId, warehouseId);
    if (available == null || row.quantity <= available) return;

    final clamped = _formatQty(available);
    row.qtyController.value = TextEditingValue(
      text: clamped,
      selection: TextSelection.collapsed(offset: clamped.length),
    );
  }

  /// Warehouse name plus its available quantity for this item, when known
  /// (fetched by _loadWarehouseStock) — matches the web release screen's
  /// "Name — Available X" dropdown option.
  String _warehouseOptionLabel(WarehouseEntry warehouse, int itemId) {
    final stocks = _stockByItem[itemId];
    if (stocks == null) return warehouse.name;
    final match = stocks.where((s) => s.warehouseId == warehouse.id);
    if (match.isEmpty) return warehouse.name;
    return AppLocalizations.of(context).quotationDetailWarehouseAvailableOption(
      warehouse.name,
      _formatQty(match.first.availableQty),
    );
  }

  /// A warning, not a hard block — the backend itself never enforced
  /// warehouse availability at release time (WarehouseItemStock is
  /// display-only there too), so this only ever protected the rep from a
  /// mistake the backend would have accepted anyway. Returns true if the
  /// rep chose to create the order despite the shortage, false if they
  /// chose to go back and fix the quantities/warehouses first.
  Future<bool> _showInsufficientStockDialog(List<String> shortages) async {
    final l10n = AppLocalizations.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.quotationDetailInsufficientStockTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.quotationDetailInsufficientStockIntro),
            const SizedBox(height: AppSpacing.sm),
            ...shortages.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $s'),
                )),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.quotationDetailInsufficientStockSuggestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.quotationDetailInsufficientStockCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.quotationDetailInsufficientStockCreateAnyway),
          ),
        ],
      ),
    );
    return proceed ?? false;
  }

  /// Records the customer's decision on this SENT quotation on the rep's
  /// behalf, then refreshes — an ACCEPTED response is what unlocks the
  /// release-into-sales-order section above, so the settings fetch behind
  /// it (skipped at initState time while the quotation was still SENT)
  /// needs to run now too.
  Future<void> _submitResponse() async {
    final token = _quotation.confirmationToken;
    if (token == null) return;
    await _performAction(
      'respond',
      () => context.read<OffersService>().recordQuotationResponse(
        _quotation.id,
        token: token,
        response: _responseValue,
        customerName: _responseCustomerNameController.text,
        comments: _responseCommentsController.text,
      ),
    );
    if (!mounted || _actionError != null) return;
    await _refresh();
    if (mounted && ['ACCEPTED', 'PARTIALLY_CONVERTED'].contains(_quotation.status)) {
      await _loadReleaseSettings();
    }
  }

  Future<void> _performAction(
    String action,
    Future<void> Function() call,
  ) async {
    setState(() {
      _busyAction = action;
      _actionError = null;
    });
    try {
      await call();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_successMessageFor(l10n, action))),
        );
      }
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } catch (_) {
      setState(
        () => _actionError = AppLocalizations.of(
          context,
        ).quotationDetailActionFailedMessage,
      );
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  String _successMessageFor(AppLocalizations l10n, String action) {
    switch (action) {
      case 'send':
        return l10n.quotationDetailSentMessage;
      case 'order':
        return l10n.quotationDetailOrderCreatedMessage;
      case 'respond':
        return l10n.quotationDetailResponseRecordedMessage;
      case 'cancel':
        return l10n.quotationDetailCancelledMessage;
      default:
        return l10n.quotationDetailActionDoneMessage;
    }
  }

  /// There's no dedicated "cancel quotation" endpoint on the backend —
  /// declining every line still open, at its full remaining quantity, is
  /// the closest equivalent available (see OffersService.declineLines).
  Future<void> _cancelQuotation(List<QuotationLine> releasableLines) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.quotationDetailCancelConfirmTitle),
        content: Text(l10n.quotationDetailCancelConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.quotationDetailCancelDismiss),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.quotationDetailCancelConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final declines = releasableLines
        .where((line) => line.remainingQuantity > 0)
        .map((line) => QuotationLineDecline(lineId: line.id, quantity: line.remainingQuantity))
        .toList();
    if (declines.isEmpty) return;

    await _performAction(
      'cancel',
      () => context.read<OffersService>().declineLines(widget.quotation.id, declines),
    );
    if (mounted && _actionError == null) {
      await _refresh();
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _pdfBusy = true;
      _actionError = null;
    });
    try {
      final bytes = await context.read<OffersService>().quotationPdfBytes(
        widget.quotation.id,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.quotation.quotationNumber}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } catch (_) {
      setState(
        () => _actionError = AppLocalizations.of(
          context,
        ).quotationDetailPdfDownloadFailedMessage,
      );
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = context.watch<ReferenceCache>();
    final l10n = AppLocalizations.of(context);
    final quotation = _quotation;
    final lines = quotation.currentVersion?.lines ?? const [];
    final releasableLines =
        quotation.currentVersion?.releasableLines ?? const [];
    final canRelease = [
      'ACCEPTED',
      'PARTIALLY_CONVERTED',
    ].contains(quotation.status);
    final showResponseSection =
        quotation.status == 'SENT' && quotation.confirmationToken != null;
    final assignedWarehouses =
        context.read<AuthService>().currentUser?.warehouses ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(quotation.quotationNumber),
        actions: const [ConnectionStatusBadge(), NotificationBell()],
      ),
      body: AppRefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            96,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    quotation.quotationNumber,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                StatusPill(value: quotation.status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SectionCard(
              title: l10n.quotationDetailSummaryTitle,
              child: Column(
                children: [
                  _kvRow(
                    l10n.quotationDetailCustomerLabel,
                    Text(reference.customerName(quotation.customerId)),
                  ),
                  _kvRow(
                    l10n.quotationDetailPaymentTermsLabel,
                    Text(quotation.paymentTerms ?? '—'),
                  ),
                  _kvRow(
                    l10n.quotationDetailCurrencyLabel,
                    Text(quotation.currency ?? '—'),
                  ),
                  _kvRow(
                    l10n.quotationDetailValidUntilLabel,
                    Text(
                      quotation.validityDays != null
                          ? l10n.quotationDetailValidUntilWithDays(
                              quotation.validUntil ?? '—',
                              '${quotation.validityDays}',
                            )
                          : (quotation.validUntil ?? '—'),
                    ),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: l10n.quotationDetailLinesTitleWithCount(
                '${quotation.version}',
                lines.length,
              ),
              child: lines.isEmpty
                  ? Text(l10n.quotationDetailNoLines)
                  : Column(
                      children: [
                        for (final line in lines)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        line.itemName ??
                                            l10n.quotationDetailItemFallback(
                                              '${line.itemId}',
                                            ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        l10n.quotationDetailQtyPriceLine(
                                              '${line.quantity}',
                                              line.uom ?? '',
                                              '${line.price}',
                                            ) +
                                            ((line.focQuantity ?? 0) > 0
                                                ? l10n.quotationDetailFocSuffix(
                                                    '${line.focQuantity}',
                                                    line.focUom ?? '',
                                                  )
                                                : ''),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                      ),
                                      Text(
                                        l10n.quotationDetailReleasedRemainingLine(
                                          '${line.releasedQuantity}',
                                          '${line.remainingQuantity}',
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                      ),
                                      Text(
                                        l10n.quotationDetailLineTotalLabel(
                                          (line.quantity * line.price)
                                              .toStringAsFixed(2),
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.quotationDetailLinesTotalLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              lines
                                  .fold<num>(0, (sum, line) => sum + line.quantity * line.price)
                                  .toStringAsFixed(2),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            if (canRelease) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: l10n.quotationDetailReleaseSectionTitle,
                child: _settingsLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_actionError != null) ...[
                            InlineErrorBanner(message: _actionError!),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          if (releasableLines.isEmpty)
                            Text(l10n.quotationDetailNoReleasableLines)
                          else ...[
                            Text(
                              _partialReleaseEnabled
                                  ? l10n.quotationDetailReleaseNotePartial
                                  : l10n.quotationDetailReleaseNoteFullOnly,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            for (final line in releasableLines)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.itemName ??
                                          l10n.quotationDetailItemFallback(
                                            '${line.itemId}',
                                          ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      l10n.quotationDetailRemainingLabelValue(
                                        '${line.remainingQuantity}',
                                        line.uom ?? '',
                                      ),
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.outline,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    _buildWarehouseStockRow(theme, l10n, line),
                                    const SizedBox(height: AppSpacing.md),
                                    // One row per warehouse split — starts
                                    // at one row (the whole line from a
                                    // single warehouse), but the rep can add
                                    // more when a single warehouse can't
                                    // cover the full quantity (e.g. 5 from
                                    // Warehouse A + 5 from Warehouse B for a
                                    // line of 10).
                                    for (var i = 0; i < _splitsFor(line).length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                                        child: Row(
                                          // start, not center: the qty field
                                          // carries a helper text (its "Max
                                          // X" hint) that the warehouse
                                          // dropdown doesn't, making it
                                          // taller — centering would misalign
                                          // the two boxes' tops/bottoms.
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: TextField(
                                                controller: _splitsFor(line)[i].qtyController,
                                                keyboardType: const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  labelText: l10n.quotationDetailReleaseQtyLabel,
                                                  helperText: () {
                                                    final row = _splitsFor(line)[i];
                                                    final available = row.warehouseId == null
                                                        ? null
                                                        : _availableForWarehouse(line.itemId, row.warehouseId!);
                                                    return available == null
                                                        ? null
                                                        : l10n.quotationDetailMaxAvailableHint(_formatQty(available));
                                                  }(),
                                                ),
                                                onChanged: (_) => setState(() {
                                                  _clampSplitRowToAvailability(line, i);
                                                }),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              flex: 5,
                                              child: Builder(builder: (context) {
                                                // Warehouses already picked on this line's *other*
                                                // rows — disabled below rather than hidden, so it's
                                                // still visible why they can't be chosen again
                                                // (there's no point splitting a line across the
                                                // same warehouse twice).
                                                final usedElsewhere = <int>{
                                                  for (var j = 0; j < _splitsFor(line).length; j++)
                                                    if (j != i && _splitsFor(line)[j].warehouseId != null)
                                                      _splitsFor(line)[j].warehouseId!,
                                                };
                                                return DropdownButtonFormField<int>(
                                                  initialValue: _splitsFor(line)[i].warehouseId,
                                                  isExpanded: true,
                                                  decoration: InputDecoration(
                                                    isDense: true,
                                                    labelText: l10n.quotationDetailWarehouseLabel,
                                                  ),
                                                  items: [
                                                    for (final warehouse in assignedWarehouses)
                                                      DropdownMenuItem(
                                                        value: warehouse.id,
                                                        enabled: !usedElsewhere.contains(warehouse.id),
                                                        child: Text(
                                                          _warehouseOptionLabel(warehouse, line.itemId),
                                                          overflow: TextOverflow.ellipsis,
                                                          style: usedElsewhere.contains(warehouse.id)
                                                              ? TextStyle(color: theme.disabledColor)
                                                              : null,
                                                        ),
                                                      ),
                                                  ],
                                                  onChanged: (value) => setState(() {
                                                    if (value != null) {
                                                      _splitsFor(line)[i].warehouseId = value;
                                                      _clampSplitRowToAvailability(line, i);
                                                    }
                                                  }),
                                                );
                                              }),
                                            ),
                                            if (_splitsFor(line).length > 1)
                                              Padding(
                                                // Lines up with the input
                                                // boxes below the (start-
                                                // aligned) row's floating
                                                // labels, not the row's top.
                                                padding: const EdgeInsets.only(top: 10),
                                                child: IconButton(
                                                  icon: const Icon(Icons.close, size: 18),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _removeSplitRow(line, i),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      runSpacing: AppSpacing.xs,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _addSplitRow(line),
                                          icon: const Icon(Icons.add, size: 16),
                                          label: Text(l10n.quotationDetailSplitWarehouseButton),
                                        ),
                                        Text(
                                          l10n.quotationDetailAllocatedLabel(
                                            _formatQty(_allocatedQuantity(line)),
                                            _formatQty(line.remainingQuantity),
                                          ),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: _allocatedQuantity(line) > line.remainingQuantity + 0.001
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                if (_partialReleaseEnabled)
                                  LoadingButton(
                                    label: l10n
                                        .quotationDetailFillFullRemainingButton,
                                    variant: LoadingButtonVariant.outlined,
                                    loading: false,
                                    onPressed: _busyAction != null
                                        ? null
                                        : () => _fillFullRemaining(
                                            releasableLines,
                                          ),
                                  ),
                                LoadingButton(
                                  label: _partialReleaseEnabled
                                      ? l10n.quotationDetailReleaseButton
                                      : l10n.quotationDetailReleaseButtonFullOnly,
                                  loading: _busyAction == 'order',
                                  onPressed:
                                      _busyAction != null ||
                                          !_canSubmitRelease(releasableLines)
                                      ? null
                                      : () => _submitRelease(releasableLines),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
              ),
            ],
            if (showResponseSection) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: l10n.quotationDetailResponseSectionTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_actionError != null) ...[
                      InlineErrorBanner(message: _actionError!),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Text(
                      l10n.quotationDetailResponseSectionNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _responseValue,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.quotationDetailResponseLabel,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'ACCEPTED',
                          child: Text(l10n.quotationDetailResponseAccepted),
                        ),
                        DropdownMenuItem(
                          value: 'REJECTED',
                          child: Text(l10n.quotationDetailResponseRejected),
                        ),
                        DropdownMenuItem(
                          value: 'NEGOTIATION_REQUESTED',
                          child: Text(l10n.quotationDetailResponseNegotiationRequested),
                        ),
                      ],
                      onChanged: (value) => setState(() {
                        if (value != null) _responseValue = value;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _responseCustomerNameController,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.quotationDetailResponseCustomerNameLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _responseCommentsController,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.quotationDetailResponseCommentsLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LoadingButton(
                      label: l10n.quotationDetailResponseSubmitButton,
                      loading: _busyAction == 'respond',
                      onPressed: _busyAction != null ? null : _submitResponse,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: l10n.quotationDetailActionsTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!canRelease && !showResponseSection && _actionError != null) ...[
                    InlineErrorBanner(message: _actionError!),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      LoadingButton(
                        label: l10n.quotationDetailDownloadPdfButton,
                        variant: LoadingButtonVariant.outlined,
                        loading: _pdfBusy,
                        onPressed: _downloadPdf,
                      ),
                      if (quotation.priceOfferRequestId != null)
                        LoadingButton(
                          label: l10n.relatedRecordsViewRequestButton,
                          variant: LoadingButtonVariant.outlined,
                          loading: false,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequestDetailScreen(
                                id: quotation.priceOfferRequestId!,
                              ),
                            ),
                          ),
                        ),
                      LoadingButton(
                        label: l10n.relatedRecordsViewSalesOrderButton,
                        variant: LoadingButtonVariant.outlined,
                        loading: false,
                        onPressed: () =>
                            openSalesOrdersForQuotation(context, quotation.id),
                      ),
                      if (quotation.status == 'DRAFT')
                        LoadingButton(
                          label: l10n.quotationDetailSendButton,
                          loading: _busyAction == 'send',
                          onPressed: _busyAction != null
                              ? null
                              : () => _performAction(
                                  'send',
                                  () => context
                                      .read<OffersService>()
                                      .sendQuotation(quotation.id),
                                ),
                        ),
                      if (canRelease && releasableLines.isNotEmpty)
                        LoadingButton(
                          label: l10n.quotationDetailCancelButton,
                          variant: LoadingButtonVariant.danger,
                          loading: _busyAction == 'cancel',
                          onPressed: _busyAction != null
                              ? null
                              : () => _cancelQuotation(releasableLines),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String label, Widget value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: value),
          ),
        ],
      ),
    );
  }
}
