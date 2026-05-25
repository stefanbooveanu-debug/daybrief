import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/voice_template_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
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
  Map<String, Color> _categoryColors =
      Map<String, Color>.from(AppColors.defaultCategoryColors);

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
        ChangeNotifierProvider(create: (_) => VoiceTemplateProvider()),
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
            theme: AppTheme.lightTheme.copyWith(
              extensions: <ThemeExtension<dynamic>>[
                CategoryColors(_categoryColors),
              ],
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              extensions: <ThemeExtension<dynamic>>[
                CategoryColors(_categoryColors),
              ],
            ),
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

}
