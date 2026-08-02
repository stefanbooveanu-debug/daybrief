import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../models/voice_template.dart';
import '../services/speech_service.dart';
import '../services/voice_command_service.dart';

class VoiceProvider with ChangeNotifier {
  VoiceProvider({
    SpeechService? speechService,
    VoiceCommandService? commandService,
  })  : _speechService = speechService ?? SpeechService(),
        _commandService = commandService ?? VoiceCommandService() {
    initialize();
  }

  final SpeechService _speechService;
  final VoiceCommandService _commandService;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _lastResult = '';
  final String _wakeWord = 'hey daybrief';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get lastResult => _lastResult;
  VoiceCommandService get commandService => _commandService;

  Future<bool> initialize() async {
    _isInitialized = await _speechService.initialize();
    notifyListeners();
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function()? onWakeWordDetected,
    String? languageCode,
  }) async {
    if (_isListening) return;

    await _speechService.startListening(
      languageCode: languageCode,
      onResult: (text) {
        _lastResult = text;
        if (_speechService.isWakeWord(text, _wakeWord)) {
          onWakeWordDetected?.call();
        }
        onResult(text);
      },
      onListeningStarted: () {
        _isListening = true;
        notifyListeners();
      },
      onListeningStopped: () {
        _isListening = false;
        notifyListeners();
      },
    );
  }

  Future<void> stopListening() async {
    await _speechService.stopListening();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    _isSpeaking = true;
    notifyListeners();
    await _speechService.speak(text);
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _speechService.stopSpeaking();
    _isSpeaking = false;
    notifyListeners();
  }

  bool isWakeWord(String text) {
    return _speechService.isWakeWord(text, _wakeWord);
  }

  Future<VoiceAction> processCommand(
    String text, {
    required List<Event> events,
    required String userId,
    VoiceTemplate? Function(String)? matchTemplate,
    Future<void> Function(Event)? onAddEvent,
    bool requireWakeWord = true,
  }) async {
    if (matchTemplate != null) {
      final template = matchTemplate(text);
      if (template != null && onAddEvent != null) {
        final event = _eventFromTemplate(template, userId);
        await onAddEvent(event);
        return VoiceSpoken('Added ${event.title}');
      }
    }
    return _commandService.processCommand(
      text,
      events,
      requireWakeWord: requireWakeWord,
    );
  }

  Event _eventFromTemplate(VoiceTemplate template, String userId) {
    final now = DateTime.now();
    final parts = (template.defaultTime ?? '09:00').split(':');
    final hour = int.tryParse(parts.elementAt(0)) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return Event(
      id: now.millisecondsSinceEpoch.toString(),
      title: template.name,
      dateTime: DateTime(now.year, now.month, now.day, hour, minute),
      category: template.category,
      userId: userId,
    );
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
