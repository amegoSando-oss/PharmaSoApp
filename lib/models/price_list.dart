import '../core/json_utils.dart';

class PriceListEntry {
  final int id;
  final String name;
  final String? code;
  final String computedStatus;
  final String? effectiveFrom;
  final String? effectiveTo;

  PriceListEntry({
    required this.id,
    required this.name,
    this.code,
    required this.computedStatus,
    this.effectiveFrom,
    this.effectiveTo,
  });

  bool get isActive => computedStatus == 'ACTIVE';

  factory PriceListEntry.fromJson(Map<String, dynamic> json) => PriceListEntry(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        code: json['code']?.toString(),
        computedStatus: json['computed_status']?.toString() ?? 'INACTIVE',
        effectiveFrom: json['effective_from']?.toString(),
        effectiveTo: json['effective_to']?.toString(),
      );
}
