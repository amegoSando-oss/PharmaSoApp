import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/text_utils.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/connection_status_service.dart';

class _ConnectionPresentation {
  final IconData icon;
  final Color color;
  final String tooltip;
  final String title;
  final String message;

  const _ConnectionPresentation({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.title,
    required this.message,
  });
}

_ConnectionPresentation _presentationFor(ConnectionQuality quality, AppLocalizations l10n) {
  switch (quality) {
    case ConnectionQuality.good:
      return _ConnectionPresentation(
        icon: Icons.cloud_done_rounded,
        color: const Color(0xFF1B8A5A),
        tooltip: l10n.connectionTooltipGood,
        title: l10n.connectionGoodTitle,
        message: l10n.connectionGoodMessage,
      );
    case ConnectionQuality.unstable:
      return _ConnectionPresentation(
        icon: Icons.cloud_sync_rounded,
        color: const Color(0xFFB4740E),
        tooltip: l10n.connectionTooltipUnstable,
        title: l10n.connectionUnstableTitle,
        message: l10n.connectionUnstableMessage,
      );
    case ConnectionQuality.offline:
      return _ConnectionPresentation(
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFD1383D),
        tooltip: l10n.connectionTooltipOffline,
        title: l10n.connectionOfflineTitle,
        message: l10n.connectionOfflineMessage,
      );
  }
}

/// AppBar icon reflecting live network + server reachability, backed by
/// [ConnectionStatusService]. Tapping it opens a detail sheet explaining the
/// current state in plain language, with a manual recheck action.
class ConnectionStatusBadge extends StatelessWidget {
  const ConnectionStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final quality = context.watch<ConnectionStatusService>().quality;
    final l10n = AppLocalizations.of(context);
    final presentation = _presentationFor(quality, l10n);

    return IconButton(
      tooltip: presentation.tooltip,
      onPressed: () => _openDetails(context),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
            child: Icon(presentation.icon, key: ValueKey(quality), color: Colors.white),
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: presentation.color,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context) {
    context.read<ConnectionStatusService>().checkNow();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConnectionDetailsSheet(),
    );
  }
}

class _ConnectionDetailsSheet extends StatelessWidget {
  const _ConnectionDetailsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final status = context.watch<ConnectionStatusService>();
    final presentation = _presentationFor(status.quality, l10n);
    final latencyMs = status.latencyMs;
    final lastCheckedAt = status.lastCheckedAt;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: presentation.color.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(presentation.icon, color: presentation.color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(presentation.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                        presentation.message,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    label: l10n.connectionNetworkLabel,
                    value: status.hasNetwork ? l10n.connectionNetworkConnected : l10n.connectionNetworkDisconnected,
                    valueColor: status.hasNetwork ? const Color(0xFF1B8A5A) : const Color(0xFFD1383D),
                  ),
                  const Divider(height: 1),
                  _DetailRow(
                    label: l10n.connectionServerLabel,
                    value: status.serverReachable ? l10n.connectionServerReachable : l10n.connectionServerUnreachable,
                    valueColor: status.serverReachable ? const Color(0xFF1B8A5A) : const Color(0xFFD1383D),
                  ),
                  if (latencyMs != null) ...[
                    const Divider(height: 1),
                    _DetailRow(label: l10n.connectionLatencyLabel, value: l10n.connectionLatencyValue(latencyMs)),
                  ],
                  if (lastCheckedAt != null) ...[
                    const Divider(height: 1),
                    _DetailRow(label: l10n.connectionLastCheckedLabel, value: formatRelativeTime(lastCheckedAt)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: status.checking ? null : () => context.read<ConnectionStatusService>().checkNow(),
                icon: status.checking
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, size: 18),
                label: Text(status.checking ? l10n.connectionCheckingLabel : l10n.connectionCheckAgainButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: valueColor)),
        ],
      ),
    );
  }
}
