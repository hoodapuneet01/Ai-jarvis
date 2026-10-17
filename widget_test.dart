import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_ai/app.dart';
import 'package:jarvis_ai/models/core_state.dart';
import 'package:jarvis_ai/screens/feature_stub_screen.dart';
import 'package:jarvis_ai/screens/settings_screen.dart';
import 'package:jarvis_ai/screens/teach_screen.dart';
import 'package:jarvis_ai/services/command_engine.dart';
import 'package:jarvis_ai/services/command_store.dart';
import 'package:jarvis_ai/widgets/ai_core.dart';

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
    test('ignores case, punctuation, spacing and a leading Jarvis', () {
      expect(normalizePhrase('Jarvis,  Good   MORNING!'), 'good morning');
      expect(normalizePhrase('good morning'), 'good morning');
      expect(normalizePhrase('jarvis'), '');
      expect(normalizePhrase('   '), '');
    });
  });

  group('CommandEngine', () {
    test('matches taught phrases and rejects unknown ones', () async {
      final store = InMemoryCommandStore();
      await store.add('good morning', 'Morning!');
      final engine = CommandEngine(store);

      expect((await engine.match('Jarvis, good morning!'))?.response, 'Morning!');
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

  testWidgets('app starts idle with the AI core visible', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(JarvisApp(store: InMemoryCommandStore()));
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

  testWidgets('a taught command gets its taught reply', (tester) async {
    usePhoneScreen(tester);
    final store = InMemoryCommandStore();
    await store.add('good morning', 'Good morning, boss');
    await tester.pumpWidget(JarvisApp(store: store));

    await tester.enterText(find.byType(TextField), 'Jarvis, good morning!');
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    await settle(tester);

    expect(find.text('Good morning, boss'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('an unknown phrase says so and offers to teach it',
      (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(JarvisApp(store: InMemoryCommandStore()));

    await tester.enterText(find.byType(TextField), 'explain java inheritance');
    await tester.tap(find.byTooltip('Send'));
    await settle(tester);
    await settle(tester);

    expect(find.text("I haven't been taught that yet."), findsOneWidget);
    expect(find.text('Teach this'), findsOneWidget);

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
    await tester.pumpWidget(JarvisApp(store: InMemoryCommandStore()));

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
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.tap(find.text('Animation preview'));
    await settle(tester);

    expect(find.byType(CorePreviewScreen), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
