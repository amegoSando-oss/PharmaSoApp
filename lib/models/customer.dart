import '../core/json_utils.dart';
import 'salesman.dart';

class Customer {
  final int id;
  final String name;
  final String? tradeName;
  final String? status;
  final List<Salesman> salesmen;

  Customer({
    required this.id,
    required this.name,
    this.tradeName,
    this.status,
    this.salesmen = const [],
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final salesmenJson = (json['salesmen'] as List?) ?? const [];
    return Customer(
      id: asInt(json['id']),
      name: json['name']?.toString() ?? '',
      tradeName: json['trade_name']?.toString(),
      status: json['status']?.toString(),
      salesmen: salesmenJson.map((s) => Salesman.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}
