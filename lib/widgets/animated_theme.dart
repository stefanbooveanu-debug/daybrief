import 'package:flutter/material.dart';

/// Pass-through wrapper (theme changes are instant — no animation).
class SmoothThemeTransition extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Duration duration;

  const SmoothThemeTransition({
    super.key,
    required this.child,
    required this.isDark,
    this.duration = Duration.zero,
  });

  @override
  Widget build(BuildContext context) => child;
}
