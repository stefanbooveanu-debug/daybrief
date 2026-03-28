import 'package:flutter/material.dart';

class SmoothThemeTransition extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Duration duration;

  const SmoothThemeTransition({
    super.key,
    required this.child,
    required this.isDark,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      duration: duration,
      curve: Curves.easeInOut,
      child: Builder(
        builder: (context) => Theme(
          data: Theme.of(context).copyWith(
            brightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: child,
        ),
      ),
    );
  }
}