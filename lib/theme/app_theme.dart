import 'package:flutter/material.dart';

import '../models/event.dart';

class AppColors {
  AppColors._();

  static const Map<String, Color> defaultCategoryColors = {
    'Work': Color(0xFF1A73E8),
    'Personal': Color(0xFF34A853),
    'Health': Color(0xFFEA4335),
    'Social': Color(0xFF9334E6),
    'Shopping': Color(0xFFFBBC04),
    'Other': Color(0xFF5F6368),
  };

  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF34A853);
  static const Color error = Color(0xFFEA4335);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onBackground = Color(0xFF202124);
  static const Color onSurface = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color divider = Color(0xFFE8EAED);
  
  static const Color gradientStart = Color(0xFF667eea);
  static const Color gradientEnd = Color(0xFF764ba2);

  static const Color cream = Color(0xFFF7F3EC);
  static const Color sand = Color(0xFFE2D7C9);
  static const Color tan = Color(0xFFBCA088);
  static const Color brown = Color(0xFF8A6A55);
  static const Color darkBrown = Color(0xFF4F3A31);

  static Color getCategoryColor(String category) {
    return defaultCategoryColors[category] ?? defaultCategoryColors['Other']!;
  }

  static Color colorForCategory(EventCategory? category) =>
      getCategoryColor((category ?? EventCategory.other).displayName);

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Work':
        return Icons.work_outline;
      case 'Personal':
        return Icons.person_outline;
      case 'Health':
        return Icons.favorite_outline;
      case 'Social':
        return Icons.people_outline;
      case 'Shopping':
        return Icons.shopping_cart_outlined;
      default:
        return Icons.event;
    }
  }

  static IconData iconForCategory(EventCategory? category) =>
      getCategoryIcon((category ?? EventCategory.other).displayName);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brown,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.brown,
        primaryContainer: AppColors.sand,
        secondary: AppColors.tan,
        secondaryContainer: AppColors.cream,
        tertiary: Color(0xFFA68B6C),
        tertiaryContainer: Color(0xFFEEE6DA),
        surface: AppColors.cream,
        onSurface: AppColors.darkBrown,
        outline: Color(0xFFD4C8B8),
      ),
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.darkBrown,
        elevation: 0,
        surfaceTintColor: AppColors.sand,
      ),
      cardTheme: CardTheme(
        color: AppColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: AppColors.sand,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.sand,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4C8B8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brown, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brown,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brown,
          side: const BorderSide(color: Color(0xFFD4C8B8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.sand,
        selectedColor: AppColors.tan,
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.darkBrown),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brown,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFD4C8B8),
        thickness: 1,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        CategoryColors(AppColors.defaultCategoryColors),
      ],
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8AB4F8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8AB4F8),
          foregroundColor: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF8AB4F8),
          side: const BorderSide(color: Color(0xFF3C3C3C)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2D2D2D),
        selectedColor: const Color(0xFF8AB4F8),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF8AB4F8),
        foregroundColor: Color(0xFF121212),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3C4043),
        thickness: 1,
      ),
      extensions: const <ThemeExtension<dynamic>>[
        CategoryColors(AppColors.defaultCategoryColors),
      ],
    );
  }
}

@immutable
class CategoryColors extends ThemeExtension<CategoryColors> {
  const CategoryColors(this.values);

  final Map<String, Color> values;

  Color colorFor(String? name) =>
      (name != null ? values[name] : null) ??
      AppColors.defaultCategoryColors[name] ??
      AppColors.defaultCategoryColors['Other']!;

  Color colorForCategory(EventCategory? category) =>
      colorFor((category ?? EventCategory.other).displayName);

  @override
  CategoryColors copyWith({Map<String, Color>? values}) =>
      CategoryColors(values ?? this.values);

  @override
  CategoryColors lerp(ThemeExtension<CategoryColors>? other, double t) {
    if (other is! CategoryColors) return this;
    return CategoryColors({
      for (final key in values.keys)
        key: Color.lerp(values[key], other.values[key], t) ?? values[key]!,
    });
  }
}