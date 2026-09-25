import '../core/json_utils.dart';

/// Mirrors NotificationResource — an in-app notification row.
class AppNotification {
  final int id;
  final String? type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime? readAt;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    this.type,
    required this.title,
    required this.message,
    this.data,
    this.readAt,
    this.createdAt,
  });

  bool get isUnread => readAt == null;

  AppNotification copyWith({DateTime? readAt}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        data: data,
        readAt: readAt ?? this.readAt,
        createdAt: createdAt,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: asInt(json['id']),
        type: json['type']?.toString(),
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        data: json['data'] is Map ? (json['data'] as Map).cast<String, dynamic>() : null,
        readAt: json['read_at'] == null ? null : DateTime.tryParse(json['read_at'].toString()),
        createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
      );
}
