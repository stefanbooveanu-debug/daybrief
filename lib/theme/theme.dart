import 'package:flutter/material.dart';

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

  static const Color primary = Color(0xFFFFD6BA);      // portocaliu pal - cel mai inchis
  static const Color secondary = Color(0xFFFFE8CD);    // piersica medie
  static const Color error = Color(0xFFEA4335);
  static const Color background = Color(0xFFFFF2EB);   // crem foarte pal
  static const Color surface = Color(0xFFFFDCDC);      // roz pal - cel mai deschis
  static const Color onPrimary = Color(0xFF5C3A1E);    // maro inchis pentru text pe primary
  static const Color onBackground = Color(0xFF4A2C1A); // maro inchis pentru text
  static const Color onSurface = Color(0xFF4A2C1A);
  static const Color textSecondary = Color(0xFF9E6B4A);
  static const Color divider = Color(0xFFFFD6BA);

  static const Color pink = Color(0xFFFFDCDC);         // roz pal (top)
  static const Color cream = Color(0xFFFFF2EB);        // crem (al doilea)
  static const Color peach = Color(0xFFFFE8CD);        // piersica (al treilea)
  static const Color apricot = Color(0xFFFFD6BA);      // cais (bottom)
  static const Color darkText = Color(0xFF4A2C1A);     // text inchis

  static Color getCategoryColor(String category) {
    return defaultCategoryColors[category] ?? defaultCategoryColors['Other']!;
  }

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
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.apricot,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.apricot,
        primaryContainer: AppColors.peach,
        secondary: AppColors.peach,
        secondaryContainer: AppColors.cream,
        tertiary: AppColors.pink,
        tertiaryContainer: AppColors.pink,
        surface: AppColors.cream,
        onSurface: AppColors.darkText,
        onPrimary: AppColors.darkText,
        outline: AppColors.apricot,
      ),
      scaffoldBackgroundColor: AppColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pink,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.peach, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.pink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.peach),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.apricot, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.apricot,
          foregroundColor: AppColors.darkText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkText,
          side: const BorderSide(color: AppColors.apricot),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.peach,
        selectedColor: AppColors.apricot,
        labelStyle: const TextStyle(fontSize: 14, color: AppColors.darkText),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.apricot,
        foregroundColor: AppColors.darkText,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.peach,
        thickness: 1,
      ),
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
    );
  }
}