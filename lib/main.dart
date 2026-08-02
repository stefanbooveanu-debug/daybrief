import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_scope.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'models/event.dart';
import 'providers/auth_provider.dart';
import 'providers/event_provider.dart';
import 'providers/family_provider.dart';
import 'providers/poll_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/voice_template_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/family_repository.dart';
import 'repositories/poll_repository.dart';
import 'repositories/share_calendar_repository.dart';
import 'repositories/voice_template_repository.dart';
import 'router/app_router.dart';
import 'services/poll_service.dart';
import 'services/share_calendar_service.dart';
import 'theme/app_theme.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    DayBriefLog.info('Firebase initialized successfully');
  } catch (e) {
    DayBriefLog.warning('Firebase initialization error', error: e);
  }

  try {
    await initializeDateFormatting('en_US');
    await initializeDateFormatting('ro_RO');
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
  Map<EventCategory, Color> _categoryColors =
      Map<EventCategory, Color>.from(AppColors.defaultCategoryColors);

  late final AuthRepository _authRepository;
  late final EventRepository _eventRepository;
  late final VoiceTemplateRepository _voiceTemplateRepository;
  late final FamilyRepository _familyRepository;
  late final PollRepository _pollRepository;
  late final ShareCalendarRepository _shareCalendarRepository;
  late final ShareCalendarService _shareCalendarService;
  late final PollService _pollService;
  late final AuthProvider _authProvider;
  late final SettingsProvider _settingsProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _eventRepository = EventRepository();
    _voiceTemplateRepository = VoiceTemplateRepository();
    _familyRepository = FamilyRepository();
    _pollRepository = PollRepository();
    _shareCalendarRepository = ShareCalendarRepository();
    _shareCalendarService = ShareCalendarService(_shareCalendarRepository);
    _pollService = PollService(_pollRepository);
    _authProvider = AuthProvider(_authRepository);
    _settingsProvider = SettingsProvider();
    _router = createAppRouter(authListenable: _authProvider);
    unawaited(_loadSettings());
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _settingsProvider.dispose();
    _router.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _settingsProvider.load();

    if (!mounted) return;
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;

      final savedColors = prefs.getString('categoryColors');
      if (savedColors != null) {
        _categoryColors = _parseColors(savedColors);
      }
      _isLoading = false;
    });
  }

  Map<EventCategory, Color> _parseColors(String data) {
    final colors = <EventCategory, Color>{};
    final parts = data.split(';');
    for (final part in parts) {
      if (part.isEmpty) continue;
      final kv = part.split(':');
      if (kv.length == 2) {
        final category = EventCategory.parse(kv[0]);
        if (category != null) {
          colors[category] = Color(int.parse(kv[1]));
        }
      }
    }
    return colors.isEmpty
        ? Map<EventCategory, Color>.from(AppColors.defaultCategoryColors)
        : colors;
  }

  String _encodeColors(Map<EventCategory, Color> colors) {
    return colors.entries
        .map((e) => '${e.key.name}:${e.value.toARGB32().toRadixString(16)}')
        .join(';');
  }

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> _saveColors(Map<EventCategory, Color> colors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categoryColors', _encodeColors(colors));
  }

  void _onCategoryColorsChanged(Map<EventCategory, Color> colors) {
    setState(() => _categoryColors = colors);
    unawaited(_saveColors(colors));
  }

  void _onThemeChanged(bool isDark) {
    if (_isDarkMode == isDark) return;
    setState(() => _isDarkMode = isDark);
    unawaited(_saveDarkMode(isDark));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: CircularProgressIndicator(
              color: _categoryColors[EventCategory.work],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<EventRepository>.value(value: _eventRepository),
        Provider<VoiceTemplateRepository>.value(
            value: _voiceTemplateRepository),
        Provider<FamilyRepository>.value(value: _familyRepository),
        Provider<PollRepository>.value(value: _pollRepository),
        Provider<ShareCalendarRepository>.value(
            value: _shareCalendarRepository),
        Provider<ShareCalendarService>.value(value: _shareCalendarService),
        Provider<PollService>.value(value: _pollService),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProxyProvider<AuthProvider, EventProvider>(
          create: (_) => EventProvider(
            authRepository: _authRepository,
            eventRepository: _eventRepository,
          ),
          update: (_, auth, previous) {
            final provider = previous ??
                EventProvider(
                  authRepository: _authRepository,
                  eventRepository: _eventRepository,
                );
            unawaited(provider.syncWithAuth(
              userId: auth.userId,
              isAuthenticated: auth.isAuthenticated,
              isDemoMode: auth.isDemoMode,
            ));
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(
          create: (_) => VoiceTemplateProvider(_voiceTemplateRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => FamilyProvider(_familyRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => PollProvider(_pollService),
        ),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: _settingsProvider,
        ),
      ],
      child: AppScope(
        categoryColors: _categoryColors,
        onCategoryColorsChanged: _onCategoryColorsChanged,
        onThemeChanged: _onThemeChanged,
        isDarkMode: _isDarkMode,
        child: ListenableBuilder(
          listenable: _settingsProvider,
          builder: (context, _) {
            final localeCode = _settingsProvider.localeCode;
            return MaterialApp.router(
              title: 'DayBrief',
              debugShowCheckedModeBanner: false,
              locale: Locale(localeCode),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
              themeAnimationDuration: Duration.zero,
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
              routerConfig: _router,
            );
          },
        ),
      ),
    );
  }
}
