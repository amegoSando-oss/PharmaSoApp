import 'package:flutter/material.dart';

import '../core/text_utils.dart';

/// A person-centric variant of [InfoTile] — shows an avatar with initials
/// (or a placeholder icon when nobody's assigned yet) alongside a small
/// eyebrow label, the person's name, and an optional code chip. Used for the
/// assigned salesman in the offer composer.
class PersonTile extends StatelessWidget {
  final String label;
  final String? name;
  final String? code;
  final String placeholder;

  const PersonTile({
    super.key,
    required this.label,
    required this.name,
    this.code,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPerson = name != null && name!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: hasPerson ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
            child: hasPerson
                ? Text(
                    initialsFor(name),
                    style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
                  )
                : Icon(Icons.person_outline, color: theme.colorScheme.outline, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPerson ? name! : placeholder,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: hasPerson ? FontWeight.w700 : FontWeight.normal,
                    fontStyle: hasPerson ? FontStyle.normal : FontStyle.italic,
                    color: hasPerson ? theme.colorScheme.onSurface : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          if (hasPerson && code != null && code!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code!,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
