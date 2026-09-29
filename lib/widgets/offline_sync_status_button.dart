import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/text_utils.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/connection_status_service.dart';
import '../services/offline_sync_service.dart';
import 'sync_dialog.dart';

/// Manual "sync now" control for the offline price-offer-request queue
/// (see Mobile Offline Sync.pdf / OfflineSyncService's doc comment) — a
/// sync icon that spins while a sync is in flight, a badge for how many
/// records are still queued, and a tooltip reporting when the last sync
/// attempt finished and whether it fully succeeded.
class OfflineSyncStatusButton extends StatefulWidget {
  const OfflineSyncStatusButton({super.key});

  @override
  State<OfflineSyncStatusButton> createState() => _OfflineSyncStatusButtonState();
}

class _OfflineSyncStatusButtonState extends State<OfflineSyncStatusButton> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    // "2m ago" needs to keep advancing even without a new sync event.
    _tickTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sync = context.watch<OfflineSyncService>();
    final connection = context.watch<ConnectionStatusService>();

    final isOffline = connection.quality == ConnectionQuality.offline ||
        !connection.serverReachable ||
        !connection.hasNetwork;

    if (sync.busy && !isOffline) {
      _spin.repeat();
    } else {
      _spin.stop();
      _spin.value = 0;
    }

    final color = isOffline
        ? theme.colorScheme.outline
        : sync.busy
            ? theme.colorScheme.primary
            : switch (sync.lastSyncResult) {
                LastSyncResult.partialFailure => theme.colorScheme.error,
                LastSyncResult.offline => theme.colorScheme.outline,
                LastSyncResult.success || null => theme.colorScheme.primary,
              };

    return Tooltip(
      message: isOffline ? l10n.connectionTooltipOffline : _statusText(l10n, sync),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: (sync.busy || isOffline) ? null : () => SyncDialog.show(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    RotationTransition(turns: _spin, child: Icon(Icons.sync, color: color, size: 22)),
                    if (!sync.busy && sync.pendingCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: isOffline ? theme.colorScheme.outline : theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            '${sync.pendingCount}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: isOffline ? theme.colorScheme.surface : theme.colorScheme.onError, fontWeight: FontWeight.w700, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isOffline ? l10n.syncStatusShortOffline : _shortCaption(l10n, sync),
                  style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortCaption(AppLocalizations l10n, OfflineSyncService sync) {
    if (sync.busy) return l10n.syncStatusShortSyncing;
    if (sync.pendingCount > 0) return l10n.syncStatusShortPending(sync.pendingCount);
    if (sync.lastSyncAt == null) return l10n.syncStatusShortNever;
    return switch (sync.lastSyncResult) {
      LastSyncResult.partialFailure => l10n.syncStatusShortFailed,
      LastSyncResult.offline => l10n.syncStatusShortOffline,
      LastSyncResult.success || null => formatRelativeTime(sync.lastSyncAt!),
    };
  }

  String _statusText(AppLocalizations l10n, OfflineSyncService sync) {
    if (sync.busy) return l10n.syncStatusSyncing;

    final lastPart = sync.lastSyncAt == null
        ? l10n.syncStatusNeverSynced
        : switch (sync.lastSyncResult) {
            LastSyncResult.partialFailure => l10n.syncStatusLastFailed(formatRelativeTime(sync.lastSyncAt!)),
            LastSyncResult.offline => l10n.syncStatusLastOffline(formatRelativeTime(sync.lastSyncAt!)),
            LastSyncResult.success || null => l10n.syncStatusLastSuccess(formatRelativeTime(sync.lastSyncAt!)),
          };

    if (sync.pendingCount == 0) return lastPart;
    return '$lastPart\n${l10n.syncStatusPendingCount(sync.pendingCount)}';
  }
}
