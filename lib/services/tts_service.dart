import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsService {
  ValueListenable<bool> get speaking;

  /// Returns null on success, or a plain-language error.
  Future<String?> speak(String text, {required double rate});

  Future<void> stop();
}

class FlutterTtsService implements TtsService {
  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> _speaking = ValueNotifier(false);
  bool _ready = false;

  @override
  ValueListenable<bool> get speaking => _speaking;

  void _setup() {
    if (_ready) return;
    _ready = true;
    _tts.setStartHandler(() => _speaking.value = true);
    _tts.setCompletionHandler(() => _speaking.value = false);
    _tts.setCancelHandler(() => _speaking.value = false);
    _tts.setErrorHandler((_) => _speaking.value = false);
  }

  @override
  Future<String?> speak(String text, {required double rate}) async {
    try {
      _setup();
      await _tts.setSpeechRate(rate);
      final result = await _tts.speak(text);
      if (result != 1) {
        return "Text-to-speech isn't available on this device.";
      }
      return null;
    } catch (e) {
      return "Couldn't speak: $e";
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } finally {
      _speaking.value = false;
    }
  }
}
