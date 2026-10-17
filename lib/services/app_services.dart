import '../settings/app_settings.dart';
import 'command_store.dart';
import 'speech_service.dart';
import 'tts_service.dart';

/// Everything the screens depend on, passed in so tests can swap in fakes.
class AppServices {
  AppServices({
    required this.store,
    required this.speech,
    required this.tts,
    required this.settings,
  });

  final CommandStore store;
  final SpeechService speech;
  final TtsService tts;
  final AppSettings settings;
}
