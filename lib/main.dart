import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
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
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isAuthenticated) {
                  return const AuthScreen();
                }
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
              },
            ),
          );
        },
      ),
    );
  }
}
