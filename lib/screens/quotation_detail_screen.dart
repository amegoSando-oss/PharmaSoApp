import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/quotation.dart';
import '../services/auth_service.dart';
import '../services/offers_service.dart';
import '../services/reference_cache.dart';
import '../theme/app_spacing.dart';
import '../utils/related_records_nav.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import '../l10n/generated/app_localizations.dart';
import 'request_detail_screen.dart';

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
  String? _busyAction;
  String? _actionError;
  bool _pdfBusy = false;

  bool _settingsLoading = true;
  bool _partialReleaseEnabled = false;
  final Map<int, int> _lineWarehouseId = {};
  final Map<int, TextEditingController> _qtyControllers = {};

  @override
  void initState() {
    super.initState();
    _loadReleaseSettings();
  }

  @override
  void dispose() {
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadReleaseSettings() async {
    final canRelease = ['ACCEPTED', 'PARTIALLY_CONVERTED'].contains(widget.quotation.status);
    if (!canRelease) {
      setState(() => _settingsLoading = false);
      return;
    }
    try {
      final enabled = await context.read<OffersService>().fetchPartialReleaseEnabled();
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

  TextEditingController _qtyControllerFor(QuotationLine line) {
    return _qtyControllers.putIfAbsent(line.id, () => TextEditingController());
  }

  void _fillFullRemaining(List<QuotationLine> releasableLines) {
    setState(() {
      for (final line in releasableLines) {
        _qtyControllerFor(line).text = '${line.remainingQuantity}';
      }
    });
  }

  bool _canSubmitRelease(List<QuotationLine> releasableLines) {
    if (releasableLines.isEmpty) return false;
    if (!_partialReleaseEnabled) {
      return releasableLines.every((line) => _lineWarehouseId[line.id] != null);
    }
    return releasableLines.any((line) {
      final quantity = num.tryParse(_qtyControllers[line.id]?.text ?? '') ?? 0;
      return _lineWarehouseId[line.id] != null && quantity > 0;
    });
  }

  Future<void> _submitRelease(List<QuotationLine> releasableLines) async {
    final lines = <OrderReleaseLine>[];
    for (final line in releasableLines) {
      final warehouseId = _lineWarehouseId[line.id];
      if (warehouseId == null) continue;
      final quantity = _partialReleaseEnabled
          ? (num.tryParse(_qtyControllers[line.id]?.text ?? '') ?? 0)
          : line.remainingQuantity;
      if (quantity <= 0) continue;
      lines.add(OrderReleaseLine(lineId: line.id, warehouseId: warehouseId, quantity: quantity));
    }
    if (lines.isEmpty) return;
    await _performAction(
      'order',
      () => context.read<OffersService>().createOrder(widget.quotation.id, lines: lines),
    );
    if (mounted && _actionError == null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _performAction(String action, Future<void> Function() call) async {
    setState(() {
      _busyAction = action;
      _actionError = null;
    });
    try {
      await call();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_successMessageFor(l10n, action))));
      }
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } catch (_) {
      setState(() => _actionError = AppLocalizations.of(context).quotationDetailActionFailedMessage);
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
      default:
        return l10n.quotationDetailActionDoneMessage;
    }
  }

  Future<void> _downloadPdf() async {
    setState(() {
      _pdfBusy = true;
      _actionError = null;
    });
    try {
      final bytes = await context.read<OffersService>().quotationPdfBytes(widget.quotation.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.quotation.quotationNumber}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } catch (_) {
      setState(() => _actionError = AppLocalizations.of(context).quotationDetailPdfDownloadFailedMessage);
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = context.watch<ReferenceCache>();
    final l10n = AppLocalizations.of(context);
    final quotation = widget.quotation;
    final lines = quotation.currentVersion?.lines ?? const [];
    final releasableLines = quotation.currentVersion?.releasableLines ?? const [];
    final canRelease = ['ACCEPTED', 'PARTIALLY_CONVERTED'].contains(quotation.status);
    final assignedWarehouses = context.read<AuthService>().currentUser?.warehouses ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(quotation.quotationNumber)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(quotation.quotationNumber, style: theme.textTheme.titleLarge)),
              StatusPill(value: quotation.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: l10n.quotationDetailSummaryTitle,
            child: Column(
              children: [
                _kvRow(l10n.quotationDetailCustomerLabel, Text(reference.customerName(quotation.customerId))),
                _kvRow(l10n.quotationDetailPaymentTermsLabel, Text(quotation.paymentTerms ?? '—')),
                _kvRow(l10n.quotationDetailCurrencyLabel, Text(quotation.currency ?? '—')),
                _kvRow(
                  l10n.quotationDetailValidUntilLabel,
                  Text(
                    quotation.validityDays != null
                        ? l10n.quotationDetailValidUntilWithDays(quotation.validUntil ?? '—', '${quotation.validityDays}')
                        : (quotation.validUntil ?? '—'),
                  ),
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.quotationDetailLinesTitle('${quotation.version}'),
            child: lines.isEmpty
                ? Text(l10n.quotationDetailNoLines)
                : Column(
                    children: [
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.itemName ?? l10n.quotationDetailItemFallback('${line.itemId}'),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      l10n.quotationDetailQtyPriceLine('${line.quantity}', line.uom ?? '', '${line.price}') +
                                          ((line.focQuantity ?? 0) > 0
                                              ? l10n.quotationDetailFocSuffix('${line.focQuantity}', line.focUom ?? '')
                                              : ''),
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                    ),
                                    Text(
                                      l10n.quotationDetailReleasedRemainingLine(
                                        '${line.releasedQuantity}',
                                        '${line.remainingQuantity}',
                                      ),
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          if (canRelease) ...[
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              title: l10n.quotationDetailReleaseSectionTitle,
              child: _settingsLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
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
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          for (final line in releasableLines)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.itemName ?? l10n.quotationDetailItemFallback('${line.itemId}'),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    l10n.quotationDetailRemainingLabelValue('${line.remainingQuantity}', line.uom ?? ''),
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      if (_partialReleaseEnabled)
                                        Expanded(
                                          child: TextField(
                                            controller: _qtyControllerFor(line),
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: InputDecoration(
                                              isDense: true,
                                              labelText: l10n.quotationDetailReleaseQtyLabel,
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      if (_partialReleaseEnabled) const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: DropdownButtonFormField<int>(
                                          initialValue: _lineWarehouseId[line.id],
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            isDense: true,
                                            labelText: l10n.quotationDetailWarehouseLabel,
                                          ),
                                          items: [
                                            for (final warehouse in assignedWarehouses)
                                              DropdownMenuItem(value: warehouse.id, child: Text(warehouse.name)),
                                          ],
                                          onChanged: (value) => setState(() {
                                            if (value != null) _lineWarehouseId[line.id] = value;
                                          }),
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
                                  label: l10n.quotationDetailFillFullRemainingButton,
                                  variant: LoadingButtonVariant.outlined,
                                  loading: false,
                                  onPressed: _busyAction != null ? null : () => _fillFullRemaining(releasableLines),
                                ),
                              LoadingButton(
                                label: _partialReleaseEnabled
                                    ? l10n.quotationDetailReleaseButton
                                    : l10n.quotationDetailReleaseButtonFullOnly,
                                loading: _busyAction == 'order',
                                onPressed: _busyAction != null || !_canSubmitRelease(releasableLines)
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
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.quotationDetailActionsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!canRelease && _actionError != null) ...[
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
                          MaterialPageRoute(builder: (_) => RequestDetailScreen(id: quotation.priceOfferRequestId!)),
                        ),
                      ),
                    LoadingButton(
                      label: l10n.relatedRecordsViewSalesOrderButton,
                      variant: LoadingButtonVariant.outlined,
                      loading: false,
                      onPressed: () => openSalesOrdersForQuotation(context, quotation.id),
                    ),
                    if (quotation.status == 'DRAFT')
                      LoadingButton(
                        label: l10n.quotationDetailSendButton,
                        loading: _busyAction == 'send',
                        onPressed: _busyAction != null
                            ? null
                            : () => _performAction('send', () => context.read<OffersService>().sendQuotation(quotation.id)),
                      ),
                  ],
                ),
              ],
            ),
          ),
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
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: value)),
        ],
      ),
    );
  }
}
