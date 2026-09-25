import 'package:flutter/material.dart';

/// A slower, more graceful page transition than the Material default (300ms,
/// fastOutSlowIn) — used wherever the app-icon Hero flies between screens
/// (splash → login/home, login → home, logout), since the default duration
/// makes that flight feel abrupt. Hero flights inherit the route's
/// transition duration, so lengthening it here smooths the icon's motion
/// along with a gentle cross-fade of the surrounding page content.
Route<T> heroPageRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 650),
    reverseTransitionDuration: const Duration(milliseconds: 650),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(opacity: curved, child: child);
    },
  );
}
