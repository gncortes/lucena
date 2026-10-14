import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/widgets/script_demo_controls.dart';

import '../../../testing/test_app.dart';

Widget _controls({
  bool playing = true,
  double progress = 0,
  Duration remaining = const Duration(seconds: 2),
  int tick = 0,
  bool canStepBack = true,
  List<String>? log,
}) => TestApp(
  locale: const Locale('pt'),
  child: Scaffold(
    body: Center(
      child: ScriptDemoControls(
        playing: playing,
        progress: progress,
        remaining: remaining,
        tick: tick,
        canStepBack: canStepBack,
        mainTooltip: 'Continuar',
        onRepeat: () => log?.add('repeat'),
        onStepBack: () => log?.add('back'),
        onToggle: () => log?.add('toggle'),
        onNext: () => log?.add('next'),
      ),
    ),
  ),
);

double _ring(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byKey(LessonScriptKeys.demoRing),
  );
  // ignore: avoid_dynamic_calls
  return (paint.painter! as dynamic).progress as double;
}

void main() {
  testWidgets('botões de 48 dp, o principal de 56; cada um chama a sua ação', (
    tester,
  ) async {
    final log = <String>[];
    await tester.pumpWidget(_controls(log: log));
    for (final key in [
      LessonScriptKeys.demoRepeat,
      LessonScriptKeys.demoStepBack,
      LessonScriptKeys.demoToggle,
    ]) {
      expect(tester.getSize(find.byKey(key)), const Size(48, 48));
    }
    expect(
      tester.getSize(find.byKey(LessonScriptKeys.primary)),
      const Size(56, 56),
    );
    expect(
      tester.getSize(find.byKey(LessonScriptKeys.demoRing)),
      const Size(64, 64),
    );
    await tester.tap(find.byKey(LessonScriptKeys.demoRepeat));
    await tester.tap(find.byKey(LessonScriptKeys.demoStepBack));
    await tester.tap(find.byKey(LessonScriptKeys.demoToggle));
    await tester.tap(find.byKey(LessonScriptKeys.primary));
    expect(log, ['repeat', 'back', 'toggle', 'next']);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('sem lance anterior, o ⏮ fica cinza e sem ação', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(_controls(canStepBack: false, log: log));
    await tester.tap(find.byKey(LessonScriptKeys.demoStepBack));
    expect(log, isEmpty);
    expect(
      tester
          .widget<IconButton>(find.byKey(LessonScriptKeys.demoStepBack))
          .onPressed,
      isNull,
    );
  });

  testWidgets('o anel enche no tempo que falta, recomeça a cada passo e para '
      'pausado', (tester) async {
    await tester.pumpWidget(_controls(progress: 0.5));
    expect(_ring(tester), closeTo(0.5, 0.01));
    await tester.pump(const Duration(seconds: 1));
    expect(_ring(tester), closeTo(0.75, 0.02));
    await tester.pump(const Duration(seconds: 1));
    expect(_ring(tester), closeTo(1, 0.01));
    // Passo novo: volta ao começo.
    await tester.pumpWidget(_controls(tick: 1));
    expect(_ring(tester), closeTo(0, 0.01));
    // Pausado: para onde está e mostra o ▶.
    await tester.pumpWidget(_controls(tick: 1, playing: false, progress: 0.3));
    await tester.pump(const Duration(seconds: 1));
    expect(_ring(tester), closeTo(0.3, 0.01));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
