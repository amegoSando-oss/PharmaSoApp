import 'package:flutter/material.dart';

import '../core/responsive.dart';

class StatusFilterOption {
  final String? key;
  final String label;
  final Color color;
  final IconData icon;
  final int count;

  StatusFilterOption({
    required this.key,
    required this.label,
    required this.color,
    required this.icon,
    required this.count,
  });
}

/// Horizontal row of tappable status cards (e.g. Draft / Pending / In
/// Approval / Rejected / Quotation Generated), each showing a live count and
/// acting as a toggle filter. Purely presentational — the screen computes
/// counts/filtering itself and passes the result in.
class StatusFilterBar extends StatelessWidget {
  final List<StatusFilterOption> options;
  final String? selectedKey;
  final ValueChanged<String?> onSelected;

  const StatusFilterBar({
    super.key,
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Tall enough for a 2-line label even in Arabic, whose line height
      // runs taller than Latin text at the same font size and was
      // overflowing the card by ~11px at 76.
      height: context.scale(92),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = option.key == selectedKey;
          return _FilterCard(option: option, isSelected: isSelected, onTap: () => onSelected(option.key));
        },
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final StatusFilterOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterCard({required this.option, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: context.scale(116),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withValues(alpha: 0.14) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? option.color : theme.colorScheme.outlineVariant, width: isSelected ? 1.4 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(option.icon, size: 16, color: option.color),
                const Spacer(),
                Text(
                  '${option.count}',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: option.color),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              option.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? option.color : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
