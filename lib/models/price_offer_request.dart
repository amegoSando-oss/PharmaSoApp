import '../core/json_utils.dart';
import 'quotation.dart';
import 'workflow.dart';

class PriceOfferLine {
  final int? id;
  final int itemId;
  final String? itemName;
  final String? uom;
  final num quantity;
  final num proposedPrice;
  final num? minimumPrice;
  final num? priceDifference;
  final String? priceStatus;
  final String? lineStatus;
  final num? focQuantity;
  final String? focUom;

  PriceOfferLine({
    this.id,
    required this.itemId,
    this.itemName,
    this.uom,
    required this.quantity,
    required this.proposedPrice,
    this.minimumPrice,
    this.priceDifference,
    this.priceStatus,
    this.lineStatus,
    this.focQuantity,
    this.focUom,
  });

  factory PriceOfferLine.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    return PriceOfferLine(
      id: asIntOrNull(json['id']),
      itemId: asInt(json['item_id']),
      itemName: item?['name']?.toString(),
      uom: json['uom']?.toString(),
      quantity: asNumOrNull(json['quantity']) ?? 0,
      proposedPrice: asNumOrNull(json['proposed_price']) ?? 0,
      minimumPrice: asNumOrNull(json['minimum_price']),
      priceDifference: asNumOrNull(json['price_difference']),
      priceStatus: json['price_status']?.toString(),
      lineStatus: json['line_status']?.toString(),
      focQuantity: asNumOrNull(json['foc_quantity']),
      focUom: json['foc_uom']?.toString(),
    );
  }
}

/// Summarizes which approval step a request is currently waiting on, from
/// the list/detail response's `approval_progress` field — used to split
/// IN_APPROVAL requests into "Pending" (still at step 1, untouched) vs
/// "In Approval" (already past step 1) on the Price Offers filter cards.
class ApprovalProgress {
  final int? currentStepSequence;

  ApprovalProgress({this.currentStepSequence});

  static ApprovalProgress? fromJsonOrNull(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final currentStep = json['current_step'];
    return ApprovalProgress(
      currentStepSequence: currentStep is Map ? asIntOrNull(currentStep['sequence']) : null,
    );
  }
}

class PriceOfferRequestSummary {
  final int id;
  final String requestNumber;
  final int customerId;
  final int priceListId;
  final String status;
  final String? approvalStatus;
  final String? pricingStatus;
  final String? submittedAt;
  final ApprovalProgress? approvalProgress;

  PriceOfferRequestSummary({
    required this.id,
    required this.requestNumber,
    required this.customerId,
    required this.priceListId,
    required this.status,
    this.approvalStatus,
    this.pricingStatus,
    this.submittedAt,
    this.approvalProgress,
  });

  /// IN_APPROVAL and still sitting at the first workflow step — i.e. no
  /// approval has been recorded on this request yet.
  bool get isPendingFirstApproval =>
      status == 'IN_APPROVAL' && (approvalProgress?.currentStepSequence ?? 1) <= 1;

  /// IN_APPROVAL and already past the first step (at least one approval
  /// already recorded, now waiting on a later approver).
  bool get isFurtherInApproval => status == 'IN_APPROVAL' && !isPendingFirstApproval;

  factory PriceOfferRequestSummary.fromJson(Map<String, dynamic> json) => PriceOfferRequestSummary(
        id: asInt(json['id']),
        requestNumber: json['request_number']?.toString() ?? '',
        customerId: asInt(json['customer_id']),
        priceListId: asInt(json['price_list_id']),
        status: json['status']?.toString() ?? '',
        approvalStatus: json['approval_status']?.toString(),
        pricingStatus: json['pricing_status']?.toString(),
        submittedAt: json['submitted_at']?.toString(),
        approvalProgress: ApprovalProgress.fromJsonOrNull(json['approval_progress']),
      );
}

class PriceOfferRequestDetail extends PriceOfferRequestSummary {
  final List<PriceOfferLine> lines;
  final Map<String, dynamic> capabilities;
  final WorkflowTimeline workflow;
  final QuotationSummary? quotation;

  PriceOfferRequestDetail({
    required super.id,
    required super.requestNumber,
    required super.customerId,
    required super.priceListId,
    required super.status,
    super.approvalStatus,
    super.pricingStatus,
    super.submittedAt,
    required this.lines,
    required this.capabilities,
    required this.workflow,
    this.quotation,
  });

  bool get canEdit => capabilities['can_edit'] == true;
  bool get canAddItem => capabilities['can_add_item'] == true;
  bool get canRemoveItem => capabilities['can_remove_item'] == true;
  bool get canSubmit => capabilities['can_submit'] == true;
  bool get canApprove => capabilities['can_approve'] == true;
  bool get canReject => capabilities['can_reject'] == true;
  bool get canReturn => capabilities['can_return'] == true;
  bool get canSkip => capabilities['can_skip'] == true;
  bool get canGenerateQuotation => capabilities['can_generate_quotation'] == true;
  bool get canSendQuotation => capabilities['can_send_quotation'] == true;
  bool get canCreateOrder => capabilities['can_create_order'] == true;

  factory PriceOfferRequestDetail.fromEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'] as Map<String, dynamic>;
    final linesJson = (data['lines'] as List?) ?? const [];
    return PriceOfferRequestDetail(
      id: asInt(data['id']),
      requestNumber: data['request_number']?.toString() ?? '',
      customerId: asInt(data['customer_id']),
      priceListId: asInt(data['price_list_id']),
      status: data['status']?.toString() ?? '',
      approvalStatus: data['approval_status']?.toString(),
      pricingStatus: data['pricing_status']?.toString(),
      submittedAt: data['submitted_at']?.toString(),
      lines: linesJson.map((l) => PriceOfferLine.fromJson(l as Map<String, dynamic>)).toList(),
      capabilities: (envelope['capabilities'] as Map?)?.cast<String, dynamic>() ?? const {},
      workflow: WorkflowTimeline.fromJson((envelope['workflow'] as Map?)?.cast<String, dynamic>()),
      quotation: QuotationSummary.fromJsonOrNull(envelope['quotation']),
    );
  }
}
