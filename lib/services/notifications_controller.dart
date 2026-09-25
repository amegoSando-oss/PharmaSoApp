import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/realtime_client.dart';
import '../models/app_notification.dart';
import 'notifications_service.dart';

/// Mirrors NotificationBell.js: loads the current user's notifications,
/// subscribes to their private Reverb channel for instant push, and keeps a
/// 90s poll running as a resilience fallback in case the socket drops
/// without the client noticing (or Reverb isn't running at all — see
/// docs/business-logic.md §12a on the backend).
class NotificationsController extends ChangeNotifier {
  static const _pollInterval = Duration(seconds: 90);

  final NotificationsService service;
  final RealtimeClient realtimeClient;

  NotificationsController(this.service, this.realtimeClient);

  List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool loading = false;
  String? error;

  Timer? _pollTimer;
  VoidCallback? _unsubscribe;
  int? _userId;

  void start(int userId) {
    if (_userId == userId) return;
    stop();
    _userId = userId;
    load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => load());
    _unsubscribe = realtimeClient.onNotification(userId, _onPush);
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _unsubscribe?.call();
    _unsubscribe = null;
    _userId = null;
    notifications = [];
    unreadCount = 0;
  }

  void _onPush(Map<String, dynamic> payload) {
    final notification = AppNotification.fromJson(payload);
    if (notifications.any((n) => n.id == notification.id)) return;
    notifications = [notification, ...notifications];
    if (notification.isUnread) unreadCount += 1;
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final page = await service.fetchNotifications();
      notifications = page.items;
      unreadCount = page.unreadCount;
      error = null;
    } catch (e) {
      error = 'Failed to load notifications.';
    }
    notifyListeners();
  }

  Future<void> markRead(AppNotification notification) async {
    if (!notification.isUnread) return;
    final index = notifications.indexWhere((n) => n.id == notification.id);
    if (index != -1) {
      notifications[index] = notification.copyWith(readAt: DateTime.now());
      unreadCount = (unreadCount - 1).clamp(0, 1 << 30);
      notifyListeners();
    }
    try {
      await service.markRead(notification.id);
    } catch (_) {
      // Non-critical — next load() will reconcile.
    }
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    notifications = notifications.map((n) => n.isUnread ? n.copyWith(readAt: now) : n).toList();
    unreadCount = 0;
    notifyListeners();
    try {
      await service.markAllRead();
    } catch (_) {
      // Non-critical — next load() will reconcile.
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
