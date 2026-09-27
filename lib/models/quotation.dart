import '../core/json_utils.dart';

class QuotationSummary {
  final int id;
  final String quotationNumber;
  final String status;
  final int version;
  final String? validUntil;
  final bool pdfReady;

  QuotationSummary({
    required this.id,
    required this.quotationNumber,
    required this.status,
    required this.version,
    this.validUntil,
    required this.pdfReady,
  });

  static QuotationSummary? fromJsonOrNull(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return QuotationSummary(
      id: asInt(json['id']),
      quotationNumber: json['quotation_number']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      version: asIntOrNull(json['version']) ?? 1,
      validUntil: json['valid_until']?.toString(),
      pdfReady: json['pdf_ready'] == true,
    );
  }
}

class QuotationLine {
  final int id;
  final int itemId;
  final String? itemName;
  final String? uom;
  final num quantity;
  final num price;
  final num? focQuantity;
  final String? focUom;
  final num? minimumPrice;
  final num releasedQuantity;
  final num declinedQuantity;
  final num remainingQuantity;

  QuotationLine({
    required this.id,
    required this.itemId,
    this.itemName,
    this.uom,
    required this.quantity,
    required this.price,
    this.focQuantity,
    this.focUom,
    this.minimumPrice,
    this.releasedQuantity = 0,
    this.declinedQuantity = 0,
    num? remainingQuantity,
  }) : remainingQuantity = remainingQuantity ?? quantity;

  factory QuotationLine.fromJson(Map<String, dynamic> json) {
    final quantity = asNumOrNull(json['quantity']) ?? 0;
    return QuotationLine(
      id: asInt(json['id']),
      itemId: asInt(json['item_id']),
      itemName: json['item_name']?.toString(),
      uom: json['uom']?.toString(),
      quantity: quantity,
      price: asNumOrNull(json['price']) ?? 0,
      focQuantity: asNumOrNull(json['foc_quantity']),
      focUom: json['foc_uom']?.toString(),
      minimumPrice: asNumOrNull(json['minimum_price']),
      releasedQuantity: asNumOrNull(json['released_quantity']) ?? 0,
      declinedQuantity: asNumOrNull(json['declined_quantity']) ?? 0,
      remainingQuantity: asNumOrNull(json['remaining_quantity']) ?? quantity,
    );
  }
}

class QuotationVersion {
  final int id;
  final int versionNumber;
  final String? status;
  final List<QuotationLine> lines;

  QuotationVersion({required this.id, required this.versionNumber, this.status, required this.lines});

  /// Lines still open for release/decline — mirrors QuotationsView.js's
  /// `releasableLines` computed property.
  List<QuotationLine> get releasableLines => lines.where((l) => l.remainingQuantity > 0).toList();

  factory QuotationVersion.fromJson(Map<String, dynamic> json) {
    final linesJson = (json['lines'] as List?) ?? const [];
    return QuotationVersion(
      id: asInt(json['id']),
      versionNumber: asIntOrNull(json['version_number']) ?? 1,
      status: json['status']?.toString(),
      lines: linesJson.map((l) => QuotationLine.fromJson(l as Map<String, dynamic>)).toList(),
    );
  }
}

/// Full quotation record (list rows and, per the web app's own behavior,
/// also used directly as "detail" data — there's no dedicated single-quotation
/// GET endpoint, so the list row IS the detail; see QuotationsView.js:61-65).
class Quotation {
  final int id;
  final String quotationNumber;
  final int customerId;
  final int salesmanId;
  final int? warehouseId;
  final String? quotationDate;
  final String? validUntil;
  final int? validityDays;
  final String? paymentTerms;
  final String? deliveryTerms;
  final String? currency;
  final String status;
  final int version;
  final List<QuotationVersion> versions;
  final int? priceOfferRequestId;

  Quotation({
    required this.id,
    required this.quotationNumber,
    required this.customerId,
    required this.salesmanId,
    this.warehouseId,
    this.quotationDate,
    this.validUntil,
    this.validityDays,
    this.paymentTerms,
    this.deliveryTerms,
    this.currency,
    required this.status,
    required this.version,
    required this.versions,
    this.priceOfferRequestId,
  });

  /// The lines to display — the highest version number available.
  QuotationVersion? get currentVersion {
    if (versions.isEmpty) return null;
    final sorted = [...versions]..sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
    return sorted.first;
  }

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final versionsJson = (json['versions'] as List?) ?? const [];
    return Quotation(
      id: asInt(json['id']),
      quotationNumber: json['quotation_number']?.toString() ?? '',
      customerId: asInt(json['customer_id']),
      salesmanId: asIntOrNull(json['salesman_id']) ?? 0,
      warehouseId: asIntOrNull(json['warehouse_id']),
      quotationDate: json['quotation_date']?.toString(),
      validUntil: json['valid_until']?.toString(),
      validityDays: asIntOrNull(json['validity_days']),
      paymentTerms: json['payment_terms']?.toString(),
      deliveryTerms: json['delivery_terms']?.toString(),
      currency: json['currency']?.toString(),
      status: json['status']?.toString() ?? '',
      version: asIntOrNull(json['version']) ?? 1,
      versions: versionsJson.map((v) => QuotationVersion.fromJson(v as Map<String, dynamic>)).toList(),
      priceOfferRequestId: asIntOrNull(json['price_offer_request_id']),
    );
  }
}
