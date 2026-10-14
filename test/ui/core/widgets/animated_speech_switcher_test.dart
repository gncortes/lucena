import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_motion.dart';
import 'package:lucena/ui/core/widgets/animated_speech_switcher.dart';

void main() {
  const below = Key('below');
  const bubble = Key('bubble');

  /// O balão com a fala [text] (uma caixa de [height]) e o que vem embaixo.
  Widget app(String text, double height, {bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SpeechPop(
              key: bubble,
              child: AnimatedSpeechSwitcher(
                speech: text,
                child: SizedBox(height: height, child: Text(text)),
              ),
            ),
            const SizedBox(key: below, height: 10),
          ],
        ),
      ),
    ),
  );

  double opacityOf(WidgetTester tester, String text) {
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(of: find.text(text), matching: find.byType(FadeTransition))
          .first,
    );
    return fade.opacity.value;
  }

  double top(WidgetTester tester) => tester.getTopLeft(find.byKey(below)).dy;

  testWidgets('fala nova: o texto troca em crossfade e a altura anda sem '
      'pulo', (tester) async {
    await tester.pumpWidget(app('um', 40));
    await tester.pumpAndSettle();
    expect(top(tester), 40);

    await tester.pumpWidget(app('dois', 100));
    await tester.pump();
    await tester.pump(AnimatedSpeechSwitcher.fade ~/ 2);
    // No meio: as duas falas na tela, uma saindo e outra entrando.
    expect(find.text('um'), findsOneWidget);
    expect(find.text('dois'), findsOneWidget);
    expect(opacityOf(tester, 'um'), inExclusiveRange(0, 1));
    expect(opacityOf(tester, 'dois'), inExclusiveRange(0, 1));

    // A altura cresce aos poucos: o que está embaixo desce sem salto.
    var last = top(tester);
    expect(last, inExclusiveRange(40, 100));
    const steps = 10;
    for (var i = 0; i < steps; i++) {
      await tester.pump(AnimatedSpeechSwitcher.resize ~/ steps);
      final now = top(tester);
      expect(now, greaterThanOrEqualTo(last));
      // Sem arranque: nenhum décimo do tempo leva mais de 20% do caminho.
      expect(now - last, lessThan(12));
      last = now;
    }
    await tester.pumpAndSettle();
    expect(top(tester), 100);
    expect(find.text('um'), findsNothing);
  });

  testWidgets('o balão diminui também animado', (tester) async {
    await tester.pumpWidget(app('um', 100));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app('dois', 40));
    await tester.pump();
    await tester.pump(AnimatedSpeechSwitcher.resize ~/ 2);
    expect(top(tester), inExclusiveRange(40, 100));
    // A fala antiga é cortada na borda que anima, não na altura da nova.
    final clip = tester.getRect(find.byType(ClipRect).last);
    expect(clip.height, inExclusiveRange(40, 100));
    expect(
      find.byWidgetPredicate((w) => w is Stack && w.clipBehavior == Clip.none),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
    expect(top(tester), 40);
  });

  testWidgets('pop só na primeira aparição', (tester) async {
    Transform scale() => tester.widget<Transform>(
      find
          .descendant(of: find.byKey(bubble), matching: find.byType(Transform))
          .first,
    );
    await tester.pumpWidget(app('um', 40));
    await tester.pump(SpeechPop.duration ~/ 2);
    expect(scale().transform.storage[0], inExclusiveRange(0.95, 1));
    await tester.pumpAndSettle();
    expect(scale().transform.storage[0], 1);

    // A fala seguinte não repete o pop.
    await tester.pumpWidget(app('dois', 40));
    await tester.pump();
    expect(scale().transform.storage[0], 1);
    await tester.pumpAndSettle();
  });

  testWidgets('movimento reduzido: troca seca, sem pop', (tester) async {
    await tester.pumpWidget(app('um', 40, reduced: true));
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    await tester.pumpWidget(app('dois', 100, reduced: true));
    await tester.pump();
    expect(find.text('um'), findsNothing);
    expect(top(tester), 100);
    expect(AppMotion.state, AnimatedSpeechSwitcher.fade);
  });
}
