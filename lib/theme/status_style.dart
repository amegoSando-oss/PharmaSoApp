import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Single source of truth for how a status string renders: color, icon and
/// a human label. Used by [StatusPill] and the workflow timeline so the two
/// don't drift into separate hardcoded switch statements.
class StatusStyle {
  final Color color;
  final IconData icon;
  final String label;

  const StatusStyle({required this.color, required this.icon, required this.label});
}

StatusStyle statusStyleFor(BuildContext context, String? value) {
  final label = _label(context, value);
  switch (value) {
    case 'APPROVED':
    case 'ACCEPTED':
    case 'ACTIVE':
    case 'OK':
    case 'PASSED':
    case 'NONE':
    case 'RELEASED':
      return StatusStyle(color: const Color(0xFF1B8A5A), icon: Icons.check_circle, label: label);
    case 'REJECTED':
    case 'BELOW_MIN':
    case 'EXPIRED':
    case 'FAILED':
    case 'HOLD':
    case 'ON_HOLD':
      return StatusStyle(color: const Color(0xFFD1383D), icon: Icons.cancel, label: label);
    case 'IN_APPROVAL':
    case 'PENDING':
    case 'SENT':
      return StatusStyle(color: const Color(0xFFB4740E), icon: Icons.schedule, label: label);
    case 'SKIPPED':
      return StatusStyle(color: const Color(0xFF6B7280), icon: Icons.remove_circle_outline, label: label);
    case 'DRAFT':
      return StatusStyle(color: const Color(0xFF475569), icon: Icons.edit_note, label: label);
    default:
      return StatusStyle(color: Theme.of(context).colorScheme.primary, icon: Icons.circle, label: label);
  }
}

String _label(BuildContext context, String? value) {
  final l10n = AppLocalizations.of(context);
  switch (value) {
    case 'APPROVED':
      return l10n.statusApproved;
    case 'ACCEPTED':
      return l10n.statusAccepted;
    case 'ACTIVE':
      return l10n.statusActive;
    case 'OK':
      return l10n.statusOk;
    case 'PASSED':
      return l10n.statusPassed;
    case 'NONE':
      return l10n.statusNone;
    case 'RELEASED':
      return l10n.statusReleased;
    case 'REJECTED':
      return l10n.statusRejected;
    case 'BELOW_MIN':
      return l10n.statusBelowMin;
    case 'EXPIRED':
      return l10n.statusExpired;
    case 'FAILED':
      return l10n.statusFailed;
    case 'HOLD':
      return l10n.statusHold;
    case 'ON_HOLD':
      return l10n.statusOnHold;
    case 'IN_APPROVAL':
      return l10n.statusInApproval;
    case 'PENDING':
      return l10n.statusPending;
    case 'SENT':
      return l10n.statusSent;
    case 'SKIPPED':
      return l10n.statusSkipped;
    case 'DRAFT':
      return l10n.statusDraft;
    case 'QUOTATION_GENERATED':
      return l10n.statusQuotationGenerated;
    default:
      final v = value ?? '—';
      return v.split('_').map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}').join(' ');
  }
}
