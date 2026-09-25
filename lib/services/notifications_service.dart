import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/app_notification.dart';

class NotificationsPage {
  final List<AppNotification> items;
  final int unreadCount;

  NotificationsPage({required this.items, required this.unreadCount});
}

class NotificationsService {
  final ApiClient apiClient;

  NotificationsService(this.apiClient);

  Future<NotificationsPage> fetchNotifications() async {
    final payload = await apiClient.get('/notifications') as Map<String, dynamic>;
    final data = (payload['data'] as List?) ?? const [];
    return NotificationsPage(
      items: data.map((n) => AppNotification.fromJson(n as Map<String, dynamic>)).toList(),
      unreadCount: asIntOrNull((payload['meta'] as Map<String, dynamic>?)?['unread_count']) ?? 0,
    );
  }

  Future<void> markRead(int id) async {
    await apiClient.post('/notifications/$id/read', prefix: 'notification-read');
  }

  Future<void> markAllRead() async {
    await apiClient.post('/notifications/read-all', prefix: 'notification-read-all');
  }
}
