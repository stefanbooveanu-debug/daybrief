import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('en_US', null);
  } catch (e) {
    // fallback
  }
  runApp(const DayBriefApp());
}

class DayBriefApp extends StatefulWidget {
  const DayBriefApp({super.key});

  @override
  State<DayBriefApp> createState() => _DayBriefAppState();
}

class _DayBriefAppState extends State<DayBriefApp> {
  bool _isDarkMode = false;
  bool _isLoading = true;
  Map<String, Color> _categoryColors = {
    'Work': const Color(0xFF1A73E8),
    'Personal': const Color(0xFF34A853),
    'Health': const Color(0xFFEA4335),
    'Social': const Color(0xFF9334E6),
    'Shopping': const Color(0xFFFBBC04),
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      
      final savedColors = prefs.getString('categoryColors');
      if (savedColors != null) {
        _categoryColors = _parseColors(savedColors);
      }
      _isLoading = false;
    });
  }

  Map<String, Color> _parseColors(String data) {
    final Map<String, Color> colors = {};
    final parts = data.split(';');
    for (final part in parts) {
      if (part.isEmpty) continue;
      final kv = part.split(':');
      if (kv.length == 2) {
        colors[kv[0]] = Color(int.parse(kv[1]));
      }
    }
    return colors.isEmpty ? _categoryColors : colors;
  }

  String _encodeColors(Map<String, Color> colors) {
    return colors.entries.map((e) => '${e.key}:${e.value.value.toRadixString(16)}').join(';');
  }

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> _saveColors(Map<String, Color> colors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoryColors', _encodeColors(colors));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: Builder(
        builder: (context) {
          if (_isLoading) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: const Color(0xFF121212),
                body: Center(
                  child: CircularProgressIndicator(
                    color: _categoryColors['Work'],
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'DayBrief',
            debugShowCheckedModeBanner: false,
            themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: _buildTheme(false),
            darkTheme: _buildTheme(true),
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isAuthenticated) {
                  return HomeScreen(
                    categoryColors: _categoryColors,
                    onCategoryColorsChanged: (colors) {
                      setState(() => _categoryColors = colors);
                      _saveColors(colors);
                    },
                    onThemeChanged: (isDark) {
                      setState(() => _isDarkMode = isDark);
                      _saveDarkMode(isDark);
                    },
                  );
                }
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(bool isDark) {
    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _categoryColors['Work']!,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: _categoryColors['Work'],
        secondary: _categoryColors['Personal'],
        error: _categoryColors['Health'],
        surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        onSurface: isDark ? Colors.white : const Color(0xFF202124),
      ),
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF202124),
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF8AB4F8) : _categoryColors['Work'],
          foregroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F3F4),
        selectedColor: isDark ? const Color(0xFF8AB4F8) : _categoryColors['Work'],
        labelStyle: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF202124)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
