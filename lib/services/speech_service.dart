import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract class SpeechService {
  ValueListenable<bool> get listening;

  /// Returns null when ready, or a plain-language reason it can't listen.
  Future<String?> prepare();

  Future<void> listen({
    required void Function(String text, bool isFinal) onText,
    required void Function() onDone,
    required void Function(String message) onError,
  });

  Future<void> stop();
}

/// Android speech recognition. Only listens while [listening] is true,
/// which only happens after the user taps the microphone.
class SttSpeechService implements SpeechService {
  final SpeechToText _stt = SpeechToText();
  final ValueNotifier<bool> _listening = ValueNotifier(false);
  bool _ready = false;
  void Function(String)? _onError;
  void Function()? _onDone;

  @override
  ValueListenable<bool> get listening => _listening;

  /// Ends a listening session once and tells the caller.
  void _finish() {
    if (!_listening.value) return;
    _listening.value = false;
    _onDone?.call();
  }

  @override
  Future<String?> prepare() async {
    if (_ready) return null;
    try {
      _ready = await _stt.initialize(
        onError: (e) {
          final was = _listening.value;
          _listening.value = false;
          if (was) _onError?.call(_describe(e.errorMsg));
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') _finish();
        },
      );
    } catch (e) {
      return 'Speech recognition failed to start: $e';
    }
    if (!_ready) {
      return "Speech recognition isn't available. Allow the microphone for "
          'this app in Android Settings, and make sure a speech service '
          '(such as Google) is installed.';
    }
    return null;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onText,
    required void Function() onDone,
    required void Function(String message) onError,
  }) async {
    _onError = onError;
    _onDone = onDone;
    _listening.value = true;
    try {
      await _stt.listen(
        onResult: (r) => onText(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      _listening.value = false;
      onError("Couldn't start listening: $e");
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _stt.stop();
    } finally {
      _finish();
    }
  }

  String _describe(String code) {
    if (code.contains('no_match') || code.contains('speech_timeout')) {
      return "Didn't catch that. Tap the microphone and try again.";
    }
    if (code.contains('permission')) {
      return 'Microphone permission is off. Allow it in Android Settings.';
    }
    if (code.contains('network')) {
      return 'Speech recognition needs a network connection on this device.';
    }
    return 'Speech recognition error: $code';
  }
}
