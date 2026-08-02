import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../utils/logger.dart';

class SpeechService {
  SpeechService({String languageCode = 'en'}) : _languageCode = languageCode;

  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isListening = false;
  String _languageCode;
  VoidCallback? _onListeningStopped;

  bool get isListening => _isListening;

  String get localeId =>
      _languageCode.toLowerCase().startsWith('ro') ? 'ro-RO' : 'en-US';

  void setLanguageCode(String languageCode) {
    _languageCode = languageCode;
  }

  Future<bool> initialize({String? languageCode}) async {
    if (languageCode != null) {
      _languageCode = languageCode;
    }
    if (_isInitialized) return true;

    try {
      if (!kIsWeb) {
        await Permission.microphone.request();
      }

      _isInitialized = await _speechToText.initialize(
        onError: (error) => DayBriefLog.warning('Speech error', error: error),
        onStatus: (status) {
          DayBriefLog.debug('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _onListeningStopped?.call();
          }
        },
      );

      if (!kIsWeb) {
        await _flutterTts.setLanguage(localeId);
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      }

      return _isInitialized;
    } catch (e) {
      DayBriefLog.error('Speech init error', error: e);
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    Function()? onListeningStarted,
    Function()? onListeningStopped,
    String? languageCode,
  }) async {
    if (languageCode != null) {
      _languageCode = languageCode;
    }
    _onListeningStopped = onListeningStopped;

    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        DayBriefLog.warning('Speech not available on this device');
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
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      DayBriefLog.error('Listen error', error: e);
      _isListening = false;
      onListeningStopped?.call();
    } finally {
      // Status callback is authoritative; this covers early failures.
      if (!_speechToText.isListening) {
        _isListening = false;
      }
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
    await _speechToText.stop();
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    if (kIsWeb) {
      await _speakWeb(text);
    } else {
      await _flutterTts.setLanguage(localeId);
      await _flutterTts.speak(text);
    }
  }

  Future<void> _speakWeb(String text) async {
    try {
      await _flutterTts.setLanguage(localeId);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
    } catch (e) {
      DayBriefLog.error('Web TTS error', error: e);
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
