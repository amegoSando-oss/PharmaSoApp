import '../core/json_utils.dart';

class WarehouseEntry {
  final int id;
  final String name;
  final String? location;

  WarehouseEntry({required this.id, required this.name, this.location});

  factory WarehouseEntry.fromJson(Map<String, dynamic> json) => WarehouseEntry(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        location: json['location']?.toString(),
      );
}
