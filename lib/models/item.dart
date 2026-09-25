import '../core/json_utils.dart';

class ItemEntry {
  final int id;
  final String name;
  final String? jdeItemNumber;
  final String? uom;
  final String? packSize;
  final String? packUnit;

  ItemEntry({
    required this.id,
    required this.name,
    this.jdeItemNumber,
    this.uom,
    this.packSize,
    this.packUnit,
  });

  String get displayName => jdeItemNumber != null && jdeItemNumber!.isNotEmpty
      ? '$name · JDE $jdeItemNumber'
      : name;

  factory ItemEntry.fromJson(Map<String, dynamic> json) => ItemEntry(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        jdeItemNumber: json['jde_item_number']?.toString(),
        uom: json['uom']?.toString(),
        packSize: json['pack_size']?.toString(),
        packUnit: json['pack_unit']?.toString(),
      );
}
