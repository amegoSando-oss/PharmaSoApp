import '../core/json_utils.dart';

class SalesOrderLine {
  final int id;
  final int itemId;
  final String? itemName;
  final String? uom;
  final num quantity;
  final num price;
  final num? focQuantity;
  final num? priceBeforeTax;
  final num? priceAfterTax;
  final bool includeTax;
  final num? taxRate;

  SalesOrderLine({
    required this.id,
    required this.itemId,
    this.itemName,
    this.uom,
    required this.quantity,
    required this.price,
    this.focQuantity,
    this.priceBeforeTax,
    this.priceAfterTax,
    this.includeTax = false,
    this.taxRate,
  });

  /// Matches OrdersView.js's lineTotal(): quantity * unit price after tax,
  /// falling back to the legacy flat `price` for pre-tax-breakdown rows.
  num get lineTotal => quantity * (priceAfterTax ?? price);

  factory SalesOrderLine.fromJson(Map<String, dynamic> json) => SalesOrderLine(
        id: asInt(json['id']),
        itemId: asInt(json['item_id']),
        itemName: json['item_name']?.toString(),
        uom: json['uom']?.toString(),
        quantity: asNumOrNull(json['quantity']) ?? 0,
        price: asNumOrNull(json['price']) ?? 0,
        focQuantity: asNumOrNull(json['foc_quantity']),
        priceBeforeTax: asNumOrNull(json['price_before_tax']),
        priceAfterTax: asNumOrNull(json['price_after_tax']),
        includeTax: json['include_tax'] == true,
        taxRate: asNumOrNull(json['tax_rate']),
      );
}

class OrderHold {
  final int id;
  final String? holdType;
  final String? reason;
  final String status;
  final String? releasedAt;

  OrderHold({required this.id, this.holdType, this.reason, required this.status, this.releasedAt});

  factory OrderHold.fromJson(Map<String, dynamic> json) => OrderHold(
        id: asInt(json['id']),
        holdType: json['hold_type']?.toString(),
        reason: json['reason']?.toString(),
        status: json['status']?.toString() ?? '',
        releasedAt: json['released_at']?.toString(),
      );
}

class SalesOrder {
  final int id;
  final String orderNumber;
  final int? quotationId;
  final int customerId;
  final int? warehouseId;
  final String? orderDate;
  final String status;
  final String? jdeOrderNumber;
  final String? creditStatus;
  final String? holdStatus;
  final int? parentSalesOrderId;
  final int? splitSequence;
  final String? customerName;
  final String? quotationNumber;
  final List<SalesOrderLine> lines;
  final List<OrderHold> holds;
  final SalesOrder? parentOrder;

  SalesOrder({
    required this.id,
    required this.orderNumber,
    this.quotationId,
    required this.customerId,
    this.warehouseId,
    this.orderDate,
    required this.status,
    this.jdeOrderNumber,
    this.creditStatus,
    this.holdStatus,
    this.parentSalesOrderId,
    this.splitSequence,
    this.customerName,
    this.quotationNumber,
    this.lines = const [],
    this.holds = const [],
    this.parentOrder,
  });

  bool get hasActiveHold => holdStatus != null && holdStatus != 'NONE';

  /// Matches OrdersView.js's orderTotal(): sum of each line's total after tax.
  num get orderTotal => lines.fold<num>(0, (sum, line) => sum + line.lineTotal);

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    final linesJson = (json['lines'] as List?) ?? const [];
    final holdsJson = (json['holds'] as List?) ?? const [];
    final parentOrderJson = json['parent_order'] as Map<String, dynamic>?;
    return SalesOrder(
      id: asInt(json['id']),
      orderNumber: json['order_number']?.toString() ?? '',
      quotationId: asIntOrNull(json['quotation_id']),
      customerId: asInt(json['customer_id']),
      warehouseId: asIntOrNull(json['warehouse_id']),
      orderDate: json['order_date']?.toString(),
      status: json['status']?.toString() ?? '',
      jdeOrderNumber: json['jde_order_number']?.toString(),
      creditStatus: json['credit_status']?.toString(),
      holdStatus: json['hold_status']?.toString(),
      parentSalesOrderId: asIntOrNull(json['parent_sales_order_id']),
      splitSequence: asIntOrNull(json['split_sequence']),
      customerName: json['customer_name']?.toString(),
      quotationNumber: json['quotation_number']?.toString(),
      lines: linesJson.map((l) => SalesOrderLine.fromJson(l as Map<String, dynamic>)).toList(),
      holds: holdsJson.map((h) => OrderHold.fromJson(h as Map<String, dynamic>)).toList(),
      parentOrder: parentOrderJson != null ? SalesOrder.fromJson(parentOrderJson) : null,
    );
  }
}
