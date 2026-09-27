import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/realtime_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/item.dart';
import '../models/price_offer_request.dart';
import '../models/quotation.dart';
import '../services/offers_service.dart';
import '../services/quotations_service.dart';
import '../services/reference_cache.dart';
import '../theme/app_spacing.dart';
import '../utils/related_records_nav.dart';
import '../widgets/app_refresh_indicator.dart';
import '../widgets/error_state.dart';
import '../widgets/loading_button.dart';
import '../widgets/section_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/status_pill.dart';
import '../widgets/workflow_timeline.dart';
import 'quotation_detail_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final int id;

  const RequestDetailScreen({super.key, required this.id});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late Future<PriceOfferRequestDetail> _future;

  String? _busyAction;
  String? _actionError;
  final _commentsController = TextEditingController();

  int? _editingLineId;
  final _editQuantityController = TextEditingController();
  final _editPriceController = TextEditingController();
  final _editReasonController = TextEditingController();
  String? _lineError;
  bool _lineBusy = false;

  bool _addingLine = false;
  ItemEntry? _newLineItem;
  final _newQuantityController = TextEditingController();
  final _newPriceController = TextEditingController();
  final _newFocPercentController = TextEditingController();

  bool _pdfBusy = false;
  bool _flash = false;

  Timer? _flashTimer;
  VoidCallback? _unsubscribeLiveUpdate;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
    context.read<ReferenceCache>().ensureLoaded();
    // Real-time: if this exact request changes (e.g. approved/rejected from
    // another device), silently refetch and briefly flash — same channel +
    // per-id matching PriceOffersView.js uses for its open detail modal.
    _unsubscribeLiveUpdate = context.read<RealtimeClient>().onLiveUpdate('price-offers', (payload) {
      if (payload['request_id']?.toString() != widget.id.toString()) return;
      _reload();
      _triggerFlash();
    });
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _editQuantityController.dispose();
    _editPriceController.dispose();
    _editReasonController.dispose();
    _newQuantityController.dispose();
    _newPriceController.dispose();
    _newFocPercentController.dispose();
    _flashTimer?.cancel();
    _unsubscribeLiveUpdate?.call();
    super.dispose();
  }

  Future<PriceOfferRequestDetail> _fetch() => context.read<OffersService>().getRequest(widget.id);

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  void _triggerFlash() {
    _flashTimer?.cancel();
    setState(() => _flash = true);
    _flashTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _flash = false);
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

  Future<void> _performAction(String action, Future<void> Function() call) async {
    setState(() {
      _busyAction = action;
      _actionError = null;
    });
    try {
      await call();
      _reload();
    } on ApiException catch (e) {
      HapticFeedback.lightImpact();
      setState(() => _actionError = e.message);
    } catch (_) {
      HapticFeedback.lightImpact();
      if (mounted) setState(() => _actionError = AppLocalizations.of(context).requestDetailActionFailedGeneric);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  void _startEdit(PriceOfferLine line) {
    setState(() {
      _editingLineId = line.id;
      _editQuantityController.text = line.quantity.toString();
      _editPriceController.text = line.proposedPrice.toString();
      _editReasonController.clear();
      _lineError = null;
    });
  }

  Future<void> _saveEdit(PriceOfferLine line) async {
    setState(() {
      _lineError = null;
      _lineBusy = true;
    });
    try {
      await context.read<OffersService>().updateLine(
            widget.id,
            line.id!,
            quantity: num.tryParse(_editQuantityController.text),
            proposedPrice: num.tryParse(_editPriceController.text),
            reason: _editReasonController.text,
          );
      setState(() => _editingLineId = null);
      _reload();
    } on ApiException catch (e) {
      setState(() => _lineError = e.message);
    } catch (_) {
      if (mounted) setState(() => _lineError = AppLocalizations.of(context).requestDetailUpdateLineFailed);
    } finally {
      if (mounted) setState(() => _lineBusy = false);
    }
  }

  Future<void> _removeLine(PriceOfferLine line) async {
    HapticFeedback.lightImpact();
    setState(() {
      _lineError = null;
      _lineBusy = true;
    });
    try {
      await context.read<OffersService>().removeLine(widget.id, line.id!);
      _reload();
    } on ApiException catch (e) {
      setState(() => _lineError = e.message);
    } catch (_) {
      if (mounted) setState(() => _lineError = AppLocalizations.of(context).requestDetailRemoveLineFailed);
    } finally {
      if (mounted) setState(() => _lineBusy = false);
    }
  }

  Future<void> _addLine() async {
    if (_newLineItem == null) return;
    final quantity = num.tryParse(_newQuantityController.text);
    final price = num.tryParse(_newPriceController.text);
    if (quantity == null || price == null) return;

    setState(() {
      _lineError = null;
      _lineBusy = true;
    });
    try {
      await context.read<OffersService>().addLine(
            widget.id,
            OfferLineInput(
              itemId: _newLineItem!.id,
              quantity: quantity,
              proposedPrice: price,
              focPercent: num.tryParse(_newFocPercentController.text),
            ),
          );
      setState(() {
        _addingLine = false;
        _newLineItem = null;
        _newQuantityController.clear();
        _newPriceController.clear();
        _newFocPercentController.clear();
      });
      _reload();
    } on ApiException catch (e) {
      setState(() => _lineError = e.message);
    } catch (_) {
      if (mounted) setState(() => _lineError = AppLocalizations.of(context).requestDetailAddLineFailed);
    } finally {
      if (mounted) setState(() => _lineBusy = false);
    }
  }

  /// There's no single-quotation GET endpoint, so releasing lines into a
  /// sales order needs the full [Quotation] (with its version/lines) fetched
  /// by number first — this reuses [QuotationDetailScreen]'s per-line
  /// release UI rather than duplicating it here with only a [QuotationSummary].
  Future<void> _openQuotationForOrder(QuotationSummary quotation) async {
    setState(() {
      _busyAction = 'order';
      _actionError = null;
    });
    try {
      final full = await context.read<QuotationsService>().findByNumber(quotation.quotationNumber);
      if (!mounted) return;
      if (full == null) {
        setState(() => _actionError = AppLocalizations.of(context).requestDetailActionFailedGeneric);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QuotationDetailScreen(quotation: full)),
      );
      if (mounted) _reload();
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } catch (_) {
      if (mounted) setState(() => _actionError = AppLocalizations.of(context).requestDetailActionFailedGeneric);
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _downloadPdf(QuotationSummary quotation) async {
    setState(() {
      _pdfBusy = true;
      _actionError = null;
    });
    try {
      final bytes = await context.read<OffersService>().quotationPdfBytes(quotation.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${quotation.quotationNumber}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } on ApiException catch (e) {
      setState(() => _actionError = e.message);
    } catch (_) {
      if (mounted) setState(() => _actionError = AppLocalizations.of(context).requestDetailDownloadPdfFailed);
    } finally {
      if (mounted) setState(() => _pdfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestDetailTitle)),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _flash ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : Colors.transparent,
        child: FutureBuilder<PriceOfferRequestDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonDetail();
            }
            if (snapshot.hasError) {
              final message =
                  snapshot.error is ApiException ? (snapshot.error as ApiException).message : l10n.requestDetailLoadError;
              return ErrorState(message: message, onRetry: _reload);
            }
            return _buildDetail(context, snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, PriceOfferRequestDetail detail) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final reference = context.watch<ReferenceCache>();

    return AppRefreshIndicator(
      onRefresh: _pullRefresh,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(detail.requestNumber, style: theme.textTheme.titleLarge)),
            StatusPill(value: detail.status),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: l10n.requestDetailSummaryTitle,
          child: Column(
            children: [
              _kvRow(l10n.requestDetailCustomerLabel, Text(reference.customerName(detail.customerId))),
              _kvRow(l10n.requestDetailPriceListLabel, Text(reference.priceListName(detail.priceListId))),
              _kvRow(l10n.requestDetailPricingLabel, StatusPill(value: detail.pricingStatus, dense: true)),
              _kvRow(l10n.requestDetailApprovalLabel, StatusPill(value: detail.approvalStatus, dense: true), isLast: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l10n.requestDetailLinesTitle,
          child: Column(
            children: [
              if (detail.lines.isEmpty) Text(l10n.requestDetailNoLines),
              for (final line in detail.lines) _buildLineCard(context, detail, line, reference),
              if (detail.canAddItem) _buildAddLineSection(context),
              if (_lineError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                InlineErrorBanner(message: _lineError!),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l10n.requestDetailWorkflowTitle,
          child: detail.workflow.hasWorkflow
              ? WorkflowTimelineView(steps: detail.workflow.steps)
              : Text(l10n.requestDetailNoWorkflow, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: l10n.requestDetailActionsTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_actionError != null) ...[
                InlineErrorBanner(message: _actionError!),
                const SizedBox(height: AppSpacing.sm),
              ],
              _buildActionArea(context, detail),
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
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Align(alignment: Alignment.centerLeft, child: value)),
        ],
      ),
    );
  }

  Widget _buildLineCard(
    BuildContext context,
    PriceOfferRequestDetail detail,
    PriceOfferLine line,
    ReferenceCache reference,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isEditing = _editingLineId == line.id;
    final isActive = line.lineStatus == null || line.lineStatus == 'ACTIVE';
    final pillValue = isActive ? line.priceStatus : line.lineStatus;
    final minimumPrice = line.minimumPrice;
    final priceDifference = line.priceDifference;
    final focPercent = line.focPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(line.itemName ?? reference.itemName(line.itemId), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _editQuantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.requestDetailQuantityLabel),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _editPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.requestDetailProposedPriceLabel),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _editReasonController,
                  decoration: InputDecoration(labelText: l10n.requestDetailReasonLabel),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _lineBusy ? null : () => setState(() => _editingLineId = null),
                      child: Text(l10n.requestDetailCancelButton),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    LoadingButton(label: l10n.requestDetailSaveChangeButton, loading: _lineBusy, onPressed: () => _saveEdit(line)),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        line.itemName ?? reference.itemName(line.itemId),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    StatusPill(value: pillValue, dense: true),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.requestDetailQtyProposed(line.quantity, line.uom ?? '', line.proposedPrice) +
                  (minimumPrice != null ? l10n.requestDetailMinSuffix(minimumPrice) : '') +
                  (priceDifference != null ? l10n.requestDetailDiffSuffix(priceDifference) : ''),
                  style: const TextStyle(color: Colors.grey),
                ),
                if ((focPercent ?? 0) > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l10n.requestDetailFocLine(focPercent ?? 0), style: const TextStyle(color: Colors.grey)),
                  ),
                if (isActive && (detail.canEdit || detail.canRemoveItem))
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (detail.canEdit)
                        TextButton(onPressed: () => _startEdit(line), child: Text(l10n.requestDetailEditButton)),
                      if (detail.canRemoveItem)
                        TextButton(
                          onPressed: _lineBusy ? null : () => _removeLine(line),
                          child: Text(l10n.requestDetailRemoveButton),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _buildAddLineSection(BuildContext context) {
    final reference = context.watch<ReferenceCache>();
    final l10n = AppLocalizations.of(context);
    if (!_addingLine) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _addingLine = true),
          icon: const Icon(Icons.add),
          label: Text(l10n.requestDetailAddLineButton),
        ),
      );
    }
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Autocomplete<ItemEntry>(
            displayStringForOption: (item) => item.displayName,
            optionsBuilder: (value) {
              if (value.text.isEmpty) return reference.items.take(20);
              final query = value.text.toLowerCase();
              return reference.items.where((item) =>
                  item.name.toLowerCase().contains(query) ||
                  (item.jdeItemNumber?.toLowerCase().contains(query) ?? false));
            },
            onSelected: (item) => setState(() => _newLineItem = item),
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              if (_newLineItem != null && controller.text != _newLineItem!.displayName) {
                controller.text = _newLineItem!.displayName;
              }
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(labelText: l10n.requestDetailItemLabel, prefixIcon: const Icon(Icons.search)),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newQuantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.requestDetailQuantityLabel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _newPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.requestDetailProposedPriceLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _newFocPercentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.requestDetailFocPercentLabel),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _lineBusy ? null : () => setState(() => _addingLine = false),
                child: Text(l10n.requestDetailCancelButton),
              ),
              const SizedBox(width: AppSpacing.sm),
              LoadingButton(
                label: l10n.requestDetailAddLineButton,
                loading: _lineBusy,
                onPressed: _newLineItem == null ? null : _addLine,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(BuildContext context, PriceOfferRequestDetail detail) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    switch (detail.status) {
      case 'DRAFT':
        if (!detail.canSubmit) {
          return Text(l10n.requestDetailNoActionsDraft, style: TextStyle(color: theme.colorScheme.outline));
        }
        return LoadingButton(
          label: l10n.requestDetailSubmitButton,
          loading: _busyAction == 'submit',
          onPressed: _busyAction != null
              ? null
              : () => _performAction('submit', () => context.read<OffersService>().submitRequest(widget.id)),
        );

      case 'IN_APPROVAL':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _commentsController,
              decoration: InputDecoration(labelText: l10n.requestDetailCommentsLabel),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (detail.canApprove)
                  LoadingButton(
                    label: l10n.requestDetailApproveStepButton,
                    loading: _busyAction == 'approve',
                    onPressed: _busyAction != null
                        ? null
                        : () => _performAction(
                              'approve',
                              () => context.read<OffersService>().approveRequest(widget.id, comments: _commentsController.text),
                            ),
                  ),
                if (detail.canReturn)
                  LoadingButton(
                    label: l10n.requestDetailReturnStepButton,
                    variant: LoadingButtonVariant.outlined,
                    loading: _busyAction == 'return',
                    onPressed: _busyAction != null
                        ? null
                        : () => _performAction(
                              'return',
                              () => context.read<OffersService>().returnRequest(widget.id, comments: _commentsController.text),
                            ),
                  ),
                if (detail.canSkip)
                  LoadingButton(
                    label: l10n.requestDetailSkipOptionalButton,
                    variant: LoadingButtonVariant.outlined,
                    loading: _busyAction == 'skip',
                    onPressed: _busyAction != null
                        ? null
                        : () => _performAction(
                              'skip',
                              () => context.read<OffersService>().skipRequest(widget.id, comments: _commentsController.text),
                            ),
                  ),
                if (detail.canReject)
                  LoadingButton(
                    label: l10n.requestDetailRejectButton,
                    variant: LoadingButtonVariant.danger,
                    loading: _busyAction == 'reject',
                    onPressed: _busyAction != null
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            _performAction(
                              'reject',
                              () => context.read<OffersService>().rejectRequest(widget.id, rejectionReason: _commentsController.text),
                            );
                          },
                  ),
              ],
            ),
          ],
        );

      case 'APPROVED':
      case 'QUOTATION_GENERATED':
        if (detail.quotation == null) {
          if (!detail.canGenerateQuotation) {
            return Text(
              l10n.requestDetailApprovedNoRights,
              style: TextStyle(color: theme.colorScheme.outline),
            );
          }
          return LoadingButton(
            label: l10n.requestDetailGenerateQuotationButton,
            loading: _busyAction == 'generate',
            onPressed: _busyAction != null
                ? null
                : () => _performAction('generate', () => context.read<OffersService>().generateQuotation(widget.id)),
          );
        }
        return _buildQuotationCard(context, detail, detail.quotation!);

      default:
        return Text(l10n.requestDetailNoActionsStatus(detail.status), style: TextStyle(color: theme.colorScheme.outline));
    }
  }

  Widget _buildQuotationCard(BuildContext context, PriceOfferRequestDetail detail, QuotationSummary quotation) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    String note;
    switch (quotation.status) {
      case 'DRAFT':
        note = l10n.requestDetailQuotationNoteDraft;
        break;
      case 'SENT':
        note = l10n.requestDetailQuotationNoteSent;
        break;
      case 'ACCEPTED':
        note = l10n.requestDetailQuotationNoteAccepted;
        break;
      case 'REJECTED':
        note = l10n.requestDetailQuotationNoteRejected;
        break;
      case 'EXPIRED':
        note = l10n.requestDetailQuotationNoteExpired;
        break;
      default:
        note = '';
    }
    final validUntil = quotation.validUntil;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quotation.quotationNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      'v${quotation.version}${validUntil != null ? l10n.requestDetailValidUntil(validUntil) : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              StatusPill(value: quotation.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              LoadingButton(
                label: l10n.requestDetailDownloadPdfButton,
                variant: LoadingButtonVariant.outlined,
                loading: _pdfBusy,
                onPressed: () => _downloadPdf(quotation),
              ),
              LoadingButton(
                label: l10n.relatedRecordsViewQuotationButton,
                variant: LoadingButtonVariant.outlined,
                loading: _busyAction == 'order',
                onPressed: _busyAction != null ? null : () => _openQuotationForOrder(quotation),
              ),
              LoadingButton(
                label: l10n.relatedRecordsViewSalesOrderButton,
                variant: LoadingButtonVariant.outlined,
                loading: false,
                onPressed: () => openSalesOrdersForQuotation(context, quotation.id),
              ),
              if (detail.canSendQuotation)
                LoadingButton(
                  label: l10n.requestDetailSendToCustomerButton,
                  loading: _busyAction == 'send',
                  onPressed: _busyAction != null
                      ? null
                      : () => _performAction('send', () => context.read<OffersService>().sendQuotation(quotation.id)),
                ),
              if (detail.canCreateOrder)
                LoadingButton(
                  label: l10n.requestDetailCreateSalesOrderButton,
                  loading: _busyAction == 'order',
                  onPressed: _busyAction != null ? null : () => _openQuotationForOrder(quotation),
                ),
            ],
          ),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm + 2),
              child: Text(note, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ),
        ],
      ),
    );
  }
}
