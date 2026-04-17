import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';

class VoiceProvider with ChangeNotifier {
  final SpeechService _speechService = SpeechService();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _lastResult = '';
  String _wakeWord = 'hey daybrief';

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get lastResult => _lastResult;

  Future<bool> initialize() async {
    _isInitialized = await _speechService.initialize();
    notifyListeners();
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function()? onWakeWordDetected,
  }) async {
    if (_isListening) return;

    await _speechService.startListening(
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

  void dispose() {
    _speechService.dispose();
  }
}
