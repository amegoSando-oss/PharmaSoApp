import '../core/json_utils.dart';

class Salesman {
  final int id;
  final String name;
  final String? code;

  Salesman({required this.id, required this.name, this.code});

  factory Salesman.fromJson(Map<String, dynamic> json) => Salesman(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        code: json['code']?.toString(),
      );
}
