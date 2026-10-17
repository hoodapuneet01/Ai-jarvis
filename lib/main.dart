import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/app_services.dart';
import 'services/command_store.dart';
import 'services/speech_service.dart';
import 'services/tts_service.dart';
import 'settings/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final store = await SqliteCommandStore.open();
  final settings = await AppSettings.load();
  runApp(JarvisApp(
    services: AppServices(
      store: store,
      speech: SttSpeechService(),
      tts: FlutterTtsService(),
      settings: settings,
    ),
  ));
}
