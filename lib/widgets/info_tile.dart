import 'package:flutter/material.dart';

/// Read-only label + value display, styled to sit alongside real form
/// fields. Replaces the anti-pattern of a disabled TextFormField backed by a
/// brand-new TextEditingController on every rebuild.
class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isPlaceholder;

  const InfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: theme.colorScheme.outline),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isPlaceholder ? theme.colorScheme.outline : theme.colorScheme.onSurface,
                    fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
