import '../core/json_utils.dart';
import 'warehouse.dart';

class AppUser {
  final int id;
  final String name;
  final String email;
  final List<String> roleNames;
  final List<WarehouseEntry> warehouses;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.roleNames,
    required this.warehouses,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List?) ?? const [];
    final warehouses = (json['warehouses'] as List?) ?? const [];
    return AppUser(
      id: asInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roleNames: roles.map((r) => (r as Map)['name']?.toString() ?? '').toList(),
      warehouses: warehouses.map((w) => WarehouseEntry.fromJson(w as Map<String, dynamic>)).toList(),
    );
  }
}
