import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/voice_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const DayBriefApp());
}

class DayBriefApp extends StatelessWidget {
  const DayBriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: MaterialApp(
        title: 'DayBrief',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            border: OutlineInputBorder(),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isAuthenticated) {
              return const HomeScreen(
                categoryColors: {
                  'Work': Color(0xFF1A73E8),
                  'Personal': Color(0xFF34A853),
                  'Health': Color(0xFFEA4335),
                  'Social': Color(0xFF9334E6),
                  'Shopping': Color(0xFFFBBC04),
                },
              );
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
