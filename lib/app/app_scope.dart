import 'package:flutter/material.dart';

import '../models/event.dart';

/// Theme and category-color callbacks shared across routed screens.
class AppScope extends InheritedWidget {
  const AppScope({
    required super.child,
    required this.categoryColors,
    required this.onCategoryColorsChanged,
    required this.onThemeChanged,
    required this.isDarkMode,
    super.key,
  });

  final Map<EventCategory, Color> categoryColors;
  final ValueChanged<Map<EventCategory, Color>> onCategoryColorsChanged;
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      oldWidget.categoryColors != categoryColors ||
      oldWidget.isDarkMode != isDarkMode;
}
