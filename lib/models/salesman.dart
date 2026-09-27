import '../core/json_utils.dart';

class Salesman {
  final int id;
  final String name;
  final String? code;
  // Present when this salesman came from a customer's `salesmen` list
  // (one row per customer/salesman/item-group assignment) — null for a
  // bare salesman lookup that isn't scoped to a customer assignment.
  final String? effectiveDate;
  final String? expiredDate;

  Salesman({required this.id, required this.name, this.code, this.effectiveDate, this.expiredDate});

  /// Mirrors RequestComposer.js's `salesmen` filter: an assignment with no
  /// effective/expired date is always active; otherwise today's date (as a
  /// date-only comparison) must fall within the range.
  bool get isActiveToday {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    if (effectiveDate != null) {
      final from = DateTime.tryParse(effectiveDate!);
      if (from != null && DateTime(from.year, from.month, from.day).isAfter(todayDateOnly)) return false;
    }
    if (expiredDate != null) {
      final to = DateTime.tryParse(expiredDate!);
      if (to != null && DateTime(to.year, to.month, to.day).isBefore(todayDateOnly)) return false;
    }
    return true;
  }

  factory Salesman.fromJson(Map<String, dynamic> json) => Salesman(
        id: asInt(json['id']),
        name: json['name']?.toString() ?? '',
        code: json['code']?.toString(),
        effectiveDate: json['effective_date']?.toString(),
        expiredDate: json['expired_date']?.toString(),
      );
}
