import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/data_sync_service.dart';
import '../services/offline_sync_service.dart';
import '../theme/app_spacing.dart';

enum _DialogPhase { confirm, running, result }

/// Modern confirm -> live checklist -> result flow for the manual "sync now"
/// action, covering both directions of the offline-sync story in one place:
/// pushing queued offline price offers up (OfflineSyncService) and pulling a
/// fresh copy of this rep's data down (DataSyncService) — so tapping the
/// sync button clearly shows the rep everything it's about to do, and then
/// proves it actually happened.
class SyncDialog extends StatefulWidget {
  const SyncDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SyncDialog(),
    );
  }

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog> {
  _DialogPhase _phase = _DialogPhase.confirm;
  SyncStepState _pushState = SyncStepState.pending;

  Future<void> _start() async {
    setState(() {
      _phase = _DialogPhase.running;
      _pushState = SyncStepState.running;
    });
    final offlineSync = context.read<OfflineSyncService>();
    final dataSync = context.read<DataSyncService>();
    await Future.wait([
      offlineSync.syncPending().then((_) {
        if (!mounted) return;
        setState(() {
          _pushState = (offlineSync.lastSyncResult == LastSyncResult.partialFailure || offlineSync.lastSyncResult == LastSyncResult.offline)
              ? SyncStepState.failed
              : SyncStepState.done;
        });
      }),
      dataSync.syncAll(),
    ]);
    if (!mounted) return;
    setState(() => _phase = _DialogPhase.result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _phase != _DialogPhase.running,
      child: AlertDialog(
        icon: Icon(
          _phase == _DialogPhase.result
              ? (_hasFailure(context) ? Icons.warning_amber_rounded : Icons.check_circle_outline)
              : Icons.sync,
          size: 32,
        ),
        title: Text(
          switch (_phase) {
            _DialogPhase.confirm => l10n.syncDialogTitle,
            _DialogPhase.running => l10n.syncDialogRunningTitle,
            _DialogPhase.result => _hasFailure(context) ? l10n.syncDialogResultPartialTitle : l10n.syncDialogResultSuccessTitle,
          },
          textAlign: TextAlign.center,
        ),
        content: SizedBox(
          width: 320,
          child: switch (_phase) {
            _DialogPhase.confirm => _ConfirmBody(),
            _DialogPhase.running || _DialogPhase.result => _ChecklistBody(pushState: _pushState),
          },
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: switch (_phase) {
          _DialogPhase.confirm => [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.syncDialogCancel)),
              FilledButton(onPressed: _start, child: Text(l10n.syncDialogSyncNow)),
            ],
          _DialogPhase.running => const [],
          _DialogPhase.result => [
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.syncDialogClose)),
            ],
        },
      ),
    );
  }

  bool _hasFailure(BuildContext context) =>
      _pushState == SyncStepState.failed || context.read<DataSyncService>().lastRunHadFailure;
}

class _ConfirmBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pendingCount = context.watch<OfflineSyncService>().pendingCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.syncDialogConfirmIntro, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        if (pendingCount > 0) _ConfirmLine(icon: Icons.cloud_upload_outlined, text: l10n.syncDialogConfirmUpload(pendingCount)),
        _ConfirmLine(icon: Icons.storefront_outlined, text: l10n.syncDialogConfirmReferenceData),
        _ConfirmLine(icon: Icons.receipt_long_outlined, text: l10n.syncDialogConfirmRecords),
      ],
    );
  }
}

class _ConfirmLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ConfirmLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _ChecklistBody extends StatelessWidget {
  final SyncStepState pushState;

  const _ChecklistBody({required this.pushState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dataSync = context.watch<DataSyncService>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChecklistRow(label: l10n.syncDialogStepUpload, state: pushState),
        for (final step in dataSync.steps)
          _ChecklistRow(
            label: switch (step.key) {
              'referenceData' => l10n.syncDialogStepReferenceData,
              'offlineReadiness' => l10n.syncDialogStepOfflineReadiness,
              'effectivePrices' => l10n.syncDialogStepEffectivePrices,
              'warehouseStock' => l10n.syncDialogStepWarehouseStock,
              'priceOfferRequests' => l10n.syncDialogStepPriceOfferRequests,
              'quotations' => l10n.syncDialogStepQuotations,
              'salesOrders' => l10n.syncDialogStepSalesOrders,
              _ => step.key,
            },
            state: step.state,
          ),
      ],
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final SyncStepState state;

  const _ChecklistRow({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget icon = switch (state) {
      SyncStepState.pending => Icon(Icons.circle_outlined, size: 18, color: theme.colorScheme.outline),
      SyncStepState.running => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      SyncStepState.done => Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
      SyncStepState.failed => Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          icon,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: state == SyncStepState.failed ? theme.colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
