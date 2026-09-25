import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/json_utils.dart';
import '../core/text_utils.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/app_notification.dart';
import '../screens/request_detail_screen.dart';
import '../services/notifications_controller.dart';
import 'empty_state.dart';

/// Bell icon with an unread-count badge, opening a modern bottom-sheet panel
/// — mirrors NotificationBell.js's bell/dropdown, redesigned for mobile as a
/// full-width sheet instead of a small anchored dropdown.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsController>().unreadCount;
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.widgetsNotificationsTooltip,
      onPressed: () => _openPanel(context),
      icon: Badge(
        label: Text(unread > 9 ? '9+' : '$unread'),
        isLabelVisible: unread > 0,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }

  void _openPanel(BuildContext context) {
    context.read<NotificationsController>().load();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationPanel(),
    );
  }
}

class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text(l10n.widgetsNotificationsTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Consumer<NotificationsController>(
                    builder: (context, controller, _) => controller.unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l10n.widgetsNewNotificationsCount(controller.unreadCount),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const Spacer(),
                  Consumer<NotificationsController>(
                    builder: (context, controller, _) => TextButton(
                      onPressed: controller.unreadCount > 0 ? controller.markAllRead : null,
                      child: Text(l10n.widgetsMarkAllReadButton),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Consumer<NotificationsController>(
                builder: (context, controller, _) {
                  if (controller.error != null && controller.notifications.isEmpty) {
                    return Center(
                      child: Text(controller.error!, style: TextStyle(color: theme.colorScheme.error)),
                    );
                  }
                  if (controller.notifications.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: l10n.widgetsNoNotificationsTitle,
                      message: l10n.widgetsNoNotificationsMessage,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: controller.notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _NotificationTile(
                        notification: controller.notifications[index],
                        onTap: () => _openNotification(context, controller, controller.notifications[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tapping a notification is a real navigation action, not just a
  /// read-receipt: mark it read, close the sheet, and jump straight to the
  /// price offer it's about (every sales-rep-facing notification type —
  /// PriceOfferStatusChanged — carries a request_id; see WorkflowService::
  /// notifyOwner() on the backend).
  Future<void> _openNotification(
    BuildContext context,
    NotificationsController controller,
    AppNotification notification,
  ) async {
    controller.markRead(notification);
    final requestId = asIntOrNull(notification.data?['request_id']);
    final navigator = Navigator.of(context);
    navigator.pop();
    if (requestId == null) return;
    navigator.push(MaterialPageRoute(builder: (_) => RequestDetailScreen(id: requestId)));
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = notification.isUnread;
    final accent = theme.colorScheme.primary;

    return Material(
      color: unread ? accent.withValues(alpha: 0.06) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: unread ? accent : Colors.transparent, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: (unread ? accent : theme.colorScheme.outline).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  unread ? Icons.notifications_active_outlined : Icons.notifications_none_outlined,
                  size: 18,
                  color: unread ? accent : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.createdAt != null ? formatRelativeTime(notification.createdAt!) : '',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.outline.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
