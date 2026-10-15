import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_ai/app.dart';
import 'package:jarvis_ai/models/core_state.dart';
import 'package:jarvis_ai/widgets/ai_core.dart';

void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('app starts offline with the AI core visible', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const JarvisApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AiCore), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Backend not configured'), findsOneWidget);

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

  testWidgets('sending without a backend reports the failure honestly',
      (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const JarvisApp());

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(find.textContaining("isn't connected"), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Offline'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('notes button opens an honest not-available screen',
      (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const JarvisApp());

    await tester.tap(find.byTooltip('Notes'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Not available yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('animation preview switches the core state', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(const JarvisApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Animation preview'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Thinking'));
    await tester.pump(const Duration(milliseconds: 500));

    final core = tester.widget<AiCore>(find.byType(AiCore));
    expect(core.state, CoreState.thinking);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
