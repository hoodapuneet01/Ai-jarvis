import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_ai/app.dart';
import 'package:jarvis_ai/config.dart';
import 'package:jarvis_ai/models/core_state.dart';
import 'package:jarvis_ai/screens/feature_stub_screen.dart';
import 'package:jarvis_ai/screens/settings_screen.dart';
import 'package:jarvis_ai/screens/teach_screen.dart';
import 'package:jarvis_ai/services/app_services.dart';
import 'package:jarvis_ai/services/command_engine.dart';
import 'package:jarvis_ai/services/command_store.dart';
import 'package:jarvis_ai/services/speech_service.dart';
import 'package:jarvis_ai/services/tts_service.dart';
import 'package:jarvis_ai/settings/app_settings.dart';
import 'package:jarvis_ai/widgets/ai_core.dart';

class FakeSpeech implements SpeechService {
  final ValueNotifier<bool> _listening = ValueNotifier(false);
  String? problem;
  void Function(String text, bool isFinal)? _onText;
  void Function()? _onDone;

  @override
  ValueListenable<bool> get listening => _listening;

  @override
  Future<String?> prepare() async => problem;

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onText,
    required void Function() onDone,
    required void Function(String message) onError,
  }) async {
    _listening.value = true;
    _onText = onText;
    _onDone = onDone;
  }

  @override
  Future<void> stop() async => finish();

  void emit(String text, {bool isFinal = false}) => _onText?.call(text, isFinal);

  void finish() {
    if (!_listening.value) return;
    _listening.value = false;
    _onDone?.call();
  }
}

class FakeTts implements TtsService {
  final ValueNotifier<bool> _speaking = ValueNotifier(false);
  final List<String> spoken = [];

  @override
  ValueListenable<bool> get speaking => _speaking;

  @override
  Future<String?> speak(String text, {required double rate}) async {
    spoken.add(text);
    return null;
  }

  @override
  Future<void> stop() async => _speaking.value = false;

  void setSpeaking(bool v) => _speaking.value = v;
}

class Rig {
  final store = InMemoryCommandStore();
  final speech = FakeSpeech();
  final tts = FakeTts();
  final settings = AppSettings();

  AppServices get services => AppServices(
        store: store,
        speech: speech,
        tts: tts,
        settings: settings,
      );
}

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('normalizePhrase', () {
    test('ignores case, punctuation, spacing and a leading wake word', () {
      expect(normalizePhrase('Hooda,  Good   MORNING!'), 'good morning');
      expect(normalizePhrase('good morning'), 'good morning');
      expect(normalizePhrase(kWakeWord), '');
      expect(normalizePhrase('   '), '');
    });
  });

  group('CommandEngine', () {
    test('matches taught phrases and rejects unknown ones', () async {
      final store = InMemoryCommandStore();
      await store.add('good morning', 'Morning!');
      final engine = CommandEngine(store);

      expect((await engine.match('Hooda, good morning!'))?.response, 'Morning!');
      expect(await engine.match('good evening'), isNull);
      expect(await engine.match(''), isNull);
    });

    test('validate rejects empty and duplicate commands', () async {
      final store = InMemoryCommandStore();
      final saved = await store.add('hello', 'Hi');
      final engine = CommandEngine(store);

      expect(await engine.validate('', 'x'), isNotNull);
      expect(await engine.validate('hey', ''), isNotNull);
      expect(await engine.validate('Hello!', 'Yo'), isNotNull);
      expect(await engine.validate('Hello!', 'Yo', ignoreId: saved.id), isNull);
      expect(await engine.validate('new phrase', 'ok'), isNull);
    });
  });

  group('AppSettings', () {
    test('speech rate is kept between 0.2 and 1.0', () {
      final s = AppSettings();
      s.setSpeechRate(5);
      expect(s.speechRate, 1.0);
      s.setSpeechRate(0);
      expect(s.speechRate, 0.2);
      s.setSpeechRate(0.6);
      expect(s.speechRate, 0.6);
    });
  });

  testWidgets('app starts idle with the AI core visible', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(JarvisApp(services: Rig().services));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AiCore), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);
    expect(find.text('Local commands, no AI model'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('every core state renders and animates without errors',
      (tester) async {
    for (final s in CoreState.values) {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Center(child: AiCore(state: s, size: 300))),
      ));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 700));
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a taught command gets its reply, and it is spoken',
      (tester) async {
    usePhoneScreen(tester);
    final rig = Rig();
    await rig.store.add('good morning', 'Good morning, boss');
    await tester.pumpWidget(JarvisApp(services: rig.services));

    await tester.enterText(find.byType(TextField), 'Hooda, good morning!');
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    await settle(tester);

    expect(find.text('Good morning, boss'), findsOneWidget);
    expect(rig.tts.spoken, contains('Good morning, boss'));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('replies are not spoken when speaking is turned off',
      (tester) async {
    usePhoneScreen(tester);
    final rig = Rig();
    rig.settings.setSpeakReplies(false);
    await rig.store.add('good morning', 'Good morning, boss');
    await tester.pumpWidget(JarvisApp(services: rig.services));

    await tester.enterText(find.byType(TextField), 'good morning');
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    await settle(tester);

    expect(find.text('Good morning, boss'), findsOneWidget);
    expect(rig.tts.spoken, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an unknown phrase says so and offers to teach it',
      (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(JarvisApp(services: Rig().services));

    await tester.enterText(find.byType(TextField), 'explain java inheritance');
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    await settle(tester);

    expect(find.text("I haven't been taught that yet."), findsOneWidget);
    expect(find.text('Teach this'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('voice: speaking a taught phrase gets the taught reply',
      (tester) async {
    usePhoneScreen(tester);
    final rig = Rig();
    await rig.store.add('good morning', 'Good morning, boss');
    await tester.pumpWidget(JarvisApp(services: rig.services));

    await tester.tap(find.byTooltip('Microphone'));
    await settle(tester);
    expect(find.text('Listening'), findsOneWidget);

    rig.speech.emit('good morning', isFinal: true);
    rig.speech.finish();
    await settle(tester);
    await settle(tester);
    await settle(tester);

    expect(find.text('Good morning, boss'), findsOneWidget);
    expect(rig.tts.spoken, contains('Good morning, boss'));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('voice: unavailable recognition shows the reason',
      (tester) async {
    usePhoneScreen(tester);
    final rig = Rig();
    rig.speech.problem = "Speech recognition isn't available.";
    await tester.pumpWidget(JarvisApp(services: rig.services));

    await tester.tap(find.byTooltip('Microphone'));
    await settle(tester);

    expect(find.textContaining("isn't available"), findsOneWidget);
    expect(find.text('Idle'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('voice: hearing nothing says so and sends nothing',
      (tester) async {
    usePhoneScreen(tester);
    final rig = Rig();
    await tester.pumpWidget(JarvisApp(services: rig.services));

    await tester.tap(find.byTooltip('Microphone'));
    await settle(tester);
    rig.speech.finish();
    await settle(tester);

    expect(find.textContaining("Didn't hear anything"), findsOneWidget);
    expect(find.text('Chat'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('stop speaking is only enabled while speaking', (tester) async {
    usePhoneScreen(tester);
    final rig = Rig();
    await tester.pumpWidget(JarvisApp(services: rig.services));

    IconButton stop() =>
        tester.widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.stop_circle_outlined));
    expect(stop().onPressed, isNull);

    rig.tts.setSpeaking(true);
    await settle(tester);
    expect(find.text('Speaking'), findsOneWidget);
    expect(stop().onPressed, isNotNull);

    await tester.tap(find.byTooltip('Stop speaking'));
    await settle(tester);
    expect(find.text('Speaking'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings: test voice speaks a sample sentence', (tester) async {
    usePhoneScreen(tester);
    final rig = Rig();
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(services: rig.services)));

    await tester.tap(find.text('Test voice'));
    await settle(tester);

    expect(rig.tts.spoken.length, 1);
    expect(rig.tts.spoken.first, contains(kAssistantName));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings: wake word is honestly marked as unavailable',
      (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(services: Rig().services)));

    expect(find.text('Wake word'), findsOneWidget);
    expect(find.textContaining('Not available'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('teaching a command saves it to the store', (tester) async {
    usePhoneScreen(tester);
    final store = InMemoryCommandStore();
    await tester.pumpWidget(MaterialApp(home: TeachScreen(store: store)));
    await settle(tester);

    expect(find.textContaining('No commands yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Teach'));
    await settle(tester);
    await tester.enterText(find.byKey(const Key('phrase')), 'open sesame');
    await tester.enterText(find.byKey(const Key('response')), 'Not yet taught actions');
    await tester.tap(find.text('Save'));
    await settle(tester);
    await settle(tester);

    expect((await store.list()).length, 1);
    expect(find.text('open sesame'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('deleting asks for confirmation first', (tester) async {
    usePhoneScreen(tester);
    final store = InMemoryCommandStore();
    await store.add('hello', 'Hi');
    await tester.pumpWidget(MaterialApp(home: TeachScreen(store: store)));
    await settle(tester);

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(find.text('Delete this command?'), findsOneWidget);
    expect((await store.list()).length, 1);

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await settle(tester);
    await settle(tester);

    expect((await store.list()).length, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('notes button opens an honest not-available screen',
      (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(JarvisApp(services: Rig().services));

    await tester.tap(find.byTooltip('Notes'));
    await settle(tester);

    expect(find.byType(FeatureStubScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FeatureStubScreen),
        matching: find.text('Not available yet'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('animation preview switches the core state', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: CorePreviewScreen()));
    await settle(tester);

    await tester.tap(find.text('Thinking'));
    await settle(tester);

    expect(tester.widget<AiCore>(find.byType(AiCore)).state, CoreState.thinking);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('settings opens the animation preview', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(services: Rig().services)));

    await tester.tap(find.text('Animation preview'));
    await settle(tester);

    expect(find.byType(CorePreviewScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
