import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user preference toggles under `settings_*` keys.
class SettingsProvider with ChangeNotifier {
  SettingsProvider();

  static const _prefix = 'settings_';

  bool _loaded = false;
  bool _notifications = true;
  bool _dailySummary = true;
  bool _voiceAssistant = true;
  bool _soundEffects = true;
  bool _hapticFeedback = true;
  bool _smartSnooze = true;
  bool _conflictDetection = true;
  TimeOfDayMinutes _morningBriefing =
      const TimeOfDayMinutes(hour: 7, minute: 0);
  String _localeCode = 'en';

  bool get isLoaded => _loaded;
  bool get notifications => _notifications;
  bool get dailySummary => _dailySummary;
  bool get voiceAssistant => _voiceAssistant;
  bool get soundEffects => _soundEffects;
  bool get hapticFeedback => _hapticFeedback;
  bool get smartSnooze => _smartSnooze;
  bool get conflictDetection => _conflictDetection;
  TimeOfDayMinutes get morningBriefing => _morningBriefing;
  String get localeCode => _localeCode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _notifications = prefs.getBool('${_prefix}notifications') ?? true;
    _dailySummary = prefs.getBool('${_prefix}dailySummary') ?? true;
    _voiceAssistant = prefs.getBool('${_prefix}voiceAssistant') ?? true;
    _soundEffects = prefs.getBool('${_prefix}soundEffects') ?? true;
    _hapticFeedback = prefs.getBool('${_prefix}hapticFeedback') ?? true;
    _smartSnooze = prefs.getBool('${_prefix}smartSnooze') ?? true;
    _conflictDetection = prefs.getBool('${_prefix}conflictDetection') ?? true;
    _localeCode = prefs.getString('${_prefix}localeCode') ?? 'en';
    final hour = prefs.getInt('${_prefix}morningBriefingHour') ?? 7;
    final minute = prefs.getInt('${_prefix}morningBriefingMinute') ?? 0;
    _morningBriefing = TimeOfDayMinutes(hour: hour, minute: minute);
    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    notifyListeners();
    await _setBool('notifications', value);
    // Real notification scheduling is out of scope for Phase 3.
  }

  Future<void> setDailySummary(bool value) async {
    _dailySummary = value;
    notifyListeners();
    await _setBool('dailySummary', value);
  }

  Future<void> setVoiceAssistant(bool value) async {
    _voiceAssistant = value;
    notifyListeners();
    await _setBool('voiceAssistant', value);
  }

  Future<void> setSoundEffects(bool value) async {
    _soundEffects = value;
    notifyListeners();
    await _setBool('soundEffects', value);
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    await _setBool('hapticFeedback', value);
  }

  Future<void> setSmartSnooze(bool value) async {
    _smartSnooze = value;
    notifyListeners();
    await _setBool('smartSnooze', value);
  }

  Future<void> setConflictDetection(bool value) async {
    _conflictDetection = value;
    notifyListeners();
    await _setBool('conflictDetection', value);
  }

  Future<void> setMorningBriefing(TimeOfDayMinutes value) async {
    _morningBriefing = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefix}morningBriefingHour', value.hour);
    await prefs.setInt('${_prefix}morningBriefingMinute', value.minute);
  }

  Future<void> setLocaleCode(String code) async {
    _localeCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}localeCode', code);
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }
}

class TimeOfDayMinutes {
  const TimeOfDayMinutes({required this.hour, required this.minute});

  final int hour;
  final int minute;

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
