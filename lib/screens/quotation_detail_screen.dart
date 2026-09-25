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
import '../widgets/error_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/section_card.dart';
import '../widgets/status_pill.dart';
import '../widgets/warehouse_picker_sheet.dart';
import '../l10n/generated/app_localizations.dart';

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

  Future<void> _createOrder() async {
    final assignedWarehouses = context.read<AuthService>().currentUser?.warehouses ?? const [];
    final warehouse = await WarehousePickerSheet.show(context, assignedWarehouses);
    if (warehouse == null || !mounted) return;
    _performAction(
      'order',
      () => context.read<OffersService>().createOrder(widget.quotation.id, warehouseId: warehouse.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = context.watch<ReferenceCache>();
    final l10n = AppLocalizations.of(context);
    final quotation = widget.quotation;
    final lines = quotation.currentVersion?.lines ?? const [];

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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: l10n.quotationDetailActionsTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_actionError != null) ...[
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
                    if (quotation.status == 'DRAFT')
                      LoadingButton(
                        label: l10n.quotationDetailSendButton,
                        loading: _busyAction == 'send',
                        onPressed: _busyAction != null
                            ? null
                            : () => _performAction('send', () => context.read<OffersService>().sendQuotation(quotation.id)),
                      ),
                    if (quotation.status == 'ACCEPTED')
                      LoadingButton(
                        label: l10n.quotationDetailCreateOrderButton,
                        loading: _busyAction == 'order',
                        onPressed: _busyAction != null ? null : _createOrder,
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
