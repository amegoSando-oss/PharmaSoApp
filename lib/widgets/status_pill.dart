import 'package:flutter/material.dart';

import '../theme/status_style.dart';

class StatusPill extends StatelessWidget {
  final String? value;
  final bool dense;

  const StatusPill({super.key, required this.value, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final style = statusStyleFor(context, value);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: dense ? 11 : 13, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(color: style.color, fontSize: dense ? 11 : 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
