import 'package:flutter/material.dart';

/// Consistent pull-to-refresh wrapper used on every scrollable screen — one
/// place to tune the indicator's look/behavior instead of repeating
/// RefreshIndicator(...) with slightly different styling per screen.
///
/// [child] must be a scrollable (ListView, CustomScrollView, ...) with
/// AlwaysScrollableScrollPhysics so the pull gesture still works when its
/// content is shorter than the viewport.
class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefreshIndicator({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      child: child,
    );
  }
}
