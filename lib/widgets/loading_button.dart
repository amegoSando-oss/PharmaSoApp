import 'package:flutter/material.dart';

enum LoadingButtonVariant { filled, outlined, tonal, danger }

/// A button whose label is swapped for a small spinner while [loading] is
/// true — this exact pattern used to be hand-copied at every action call
/// site (login, composer, and every lifecycle action on the detail screen).
class LoadingButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final LoadingButtonVariant variant;
  final IconData? icon;

  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.variant = LoadingButtonVariant.filled,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spinnerColor = switch (variant) {
      LoadingButtonVariant.filled => scheme.onPrimary,
      LoadingButtonVariant.danger => scheme.onErrorContainer,
      LoadingButtonVariant.outlined || LoadingButtonVariant.tonal => scheme.primary,
    };

    final child = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: spinnerColor),
          )
        : icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(label)],
              );

    final pressed = loading ? null : onPressed;

    switch (variant) {
      case LoadingButtonVariant.filled:
        return FilledButton(onPressed: pressed, child: child);
      case LoadingButtonVariant.outlined:
        return OutlinedButton(onPressed: pressed, child: child);
      case LoadingButtonVariant.tonal:
        return FilledButton.tonal(onPressed: pressed, child: child);
      case LoadingButtonVariant.danger:
        return FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
          ),
          onPressed: pressed,
          child: child,
        );
    }
  }
}
