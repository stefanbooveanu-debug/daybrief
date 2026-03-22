import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
      
      if (!kIsWeb) {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      }
      
      return _isInitialized;
    } catch (e) {
      print('Speech init error: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        print('Speech not available on this device');
        return;
      }
    }

    if (_isListening) return;

    _isListening = true;
    onListeningStarted?.call();

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      print('Listen error: $e');
      _isListening = false;
      onListeningStopped?.call();
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _speechToText.stop();
  }

  Future<void> speak(String text) async {
    if (kIsWeb) {
      await _speakWeb(text);
    } else {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _speakWeb(String text) async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
    } catch (e) {
      print('Web TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  bool isWakeWord(String text, String wakeWord) {
    return text.toLowerCase().contains(wakeWord.toLowerCase());
  }

  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
  }
}
