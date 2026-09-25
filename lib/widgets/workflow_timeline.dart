import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/workflow.dart';
import '../theme/status_style.dart';

/// Renders a [WorkflowTimeline] as a connected vertical timeline — each step
/// gets a status-colored marker, with a line threading through to the next
/// step, instead of a set of unconnected rows.
class WorkflowTimelineView extends StatelessWidget {
  final List<WorkflowStep> steps;

  const WorkflowTimelineView({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final WorkflowStep step;
  final bool isLast;

  const _StepRow({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final style = statusStyleFor(context, step.status);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: style.color.withValues(alpha: 0.4)),
                ),
                child: Icon(style.icon, size: 15, color: style.color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.roleName ?? step.name,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(style.label, style: TextStyle(color: style.color, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (step.comments != null && step.comments!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(step.comments!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                    ),
                  if (step.rejectionReason != null && step.rejectionReason!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.widgetsRejectedReason(step.rejectionReason!),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  if (step.completedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        step.completedAt!,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
