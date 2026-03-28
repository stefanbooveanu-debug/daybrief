import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';

class VoiceProvider with ChangeNotifier {
  SpeechService? _speechService;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _lastResult = '';
  final String _wakeWord = 'hey daybrief';
  String? _error;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get lastResult => _lastResult;
  String? get error => _error;

  SpeechService get speechService {
    _speechService ??= SpeechService();
    return _speechService!;
  }

  Future<bool> initialize() async {
    try {
      _isInitialized = await speechService.initialize();
      notifyListeners();
      return _isInitialized;
    } catch (e) {
      _error = 'Failed to initialize speech service';
      notifyListeners();
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function()? onWakeWordDetected,
  }) async {
    if (_isListening) return;

    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        _error = 'Speech service not available';
        notifyListeners();
        return;
      }
    }

    try {
      await speechService.startListening(
        onResult: (text) {
          _lastResult = text;
          if (speechService.isWakeWord(text, _wakeWord)) {
            onWakeWordDetected?.call();
          }
          onResult(text);
        },
        onListeningStarted: () {
          _isListening = true;
          _error = null;
          notifyListeners();
        },
        onListeningStopped: () {
          _isListening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to start listening';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await speechService.stopListening();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to stop listening';
      notifyListeners();
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;

    try {
      _isSpeaking = true;
      _error = null;
      notifyListeners();
      await speechService.speak(text);
    } catch (e) {
      _error = 'Failed to speak';
    } finally {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    try {
      await speechService.stopSpeaking();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to stop speaking';
      notifyListeners();
    }
  }

  bool isWakeWord(String text) {
    return speechService.isWakeWord(text, _wakeWord);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService?.dispose();
    _speechService = null;
    super.dispose();
  }
}
