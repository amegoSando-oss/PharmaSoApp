import 'package:flutter/material.dart';

/// Coarse screen-size bucket — phone-small / phone / tablet+.
enum DeviceType { compact, standard, expanded }

/// Screen-size-aware helpers available on any [BuildContext] without a
/// wrapper widget — a companion to the flat [AppSpacing] scale for the
/// handful of places that size themselves in raw pixels (icon boxes, card
/// widths) and need to adapt across phones/tablets/font scales instead of
/// hardcoding one number tuned for a single device.
extension Responsive on BuildContext {
  Size get _size => MediaQuery.sizeOf(this);

  double get screenWidth => _size.width;
  double get screenHeight => _size.height;

  DeviceType get deviceType {
    if (screenWidth >= 600) return DeviceType.expanded; // tablets/foldables
    if (screenWidth < 360) return DeviceType.compact; // small phones (SE-class)
    return DeviceType.standard;
  }

  bool get isTablet => deviceType == DeviceType.expanded;
  bool get isCompactPhone => deviceType == DeviceType.compact;

  /// Scales [value] against a 390-logical-px reference width (standard
  /// iPhone), clamped to ±~25% so tablets don't get comically large fixed
  /// boxes and small phones don't get crushed.
  double scale(double value) => value * (screenWidth / 390).clamp(0.85, 1.25);

  /// Screen-edge padding that widens slightly on tablets instead of content
  /// stretching edge-to-edge.
  double get horizontalPadding => isTablet ? 32 : (isCompactPhone ? 12 : 16);
}
