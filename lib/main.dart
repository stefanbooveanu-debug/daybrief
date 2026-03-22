import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DayBriefApp());
}

class DayBriefApp extends StatefulWidget {
  const DayBriefApp({super.key});

  @override
  State<DayBriefApp> createState() => _DayBriefAppState();
}

class _DayBriefAppState extends State<DayBriefApp> {
  bool _isDarkMode = false;
  Map<String, Color> _categoryColors = {
    'Work': const Color(0xFF1A73E8),
    'Personal': const Color(0xFF34A853),
    'Health': const Color(0xFFEA4335),
    'Social': const Color(0xFF9334E6),
    'Shopping': const Color(0xFFFBBC04),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DayBrief',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _categoryColors['Work']!,
          brightness: Brightness.light,
        ).copyWith(
          primary: _categoryColors['Work'],
          secondary: _categoryColors['Personal'],
          error: _categoryColors['Health'],
          surface: Colors.white,
          onSurface: const Color(0xFF202124),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF202124),
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _categoryColors['Work'],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1F3F4),
          selectedColor: _categoryColors['Work'],
          labelStyle: const TextStyle(fontSize: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _categoryColors['Work']!,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF8AB4F8),
          secondary: const Color(0xFF81C995),
          error: const Color(0xFFF28B82),
          surface: const Color(0xFF1E1E1E),
          onSurface: Colors.white,
          surfaceContainerHighest: const Color(0xFF2D2D2D),
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
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2D2D2D),
          selectedColor: const Color(0xFF8AB4F8),
          labelStyle: const TextStyle(fontSize: 14, color: Colors.white),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: HomeScreen(
        categoryColors: _categoryColors,
        onCategoryColorsChanged: (colors) {
          setState(() => _categoryColors = colors);
        },
        onThemeChanged: (isDark) {
          setState(() => _isDarkMode = isDark);
        },
      ),
    );
  }
}
