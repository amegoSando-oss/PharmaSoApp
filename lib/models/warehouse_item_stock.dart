import '../core/json_utils.dart';

/// Display-only warehouse stock for one item — mirrors
/// WarehouseItemStockResource, used to show per-warehouse On hand/Committed/
/// Available figures in the offer composer as the web app does
/// (resources/js/features/requests/RequestComposer.js). No warehouse is
/// assigned at price-offer time; this is purely informational.
class WarehouseItemStock {
  final int warehouseId;
  final String? warehouseName;
  final num onHandQty;
  final num committedQty;
  final num availableQty;

  WarehouseItemStock({
    required this.warehouseId,
    this.warehouseName,
    required this.onHandQty,
    required this.committedQty,
    required this.availableQty,
  });

  factory WarehouseItemStock.fromJson(Map<String, dynamic> json) => WarehouseItemStock(
        warehouseId: asInt(json['warehouse_id']),
        warehouseName: json['warehouse_name']?.toString(),
        onHandQty: asNumOrNull(json['on_hand_qty']) ?? 0,
        committedQty: asNumOrNull(json['committed_qty']) ?? 0,
        availableQty: asNumOrNull(json['available_qty']) ?? 0,
      );
}
