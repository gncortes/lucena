import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/balao_viktor.dart';

/// H-ANI-09: o balão entra a partir do bico em 280 ms e a fala troca com a
/// antiga saindo em 90 ms e a nova entrando em 210 ms.
void main() {
  Widget tela(String fala, {bool reduzir = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduzir),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: BalaoViktor(
            speech: fala,
            tail: BalloonTail.down,
            child: Text(fala),
          ),
        ),
      ),
    ),
  );

  Finder pop() => find.byType(SpeechPop);

  Transform escala(WidgetTester tester) => tester.widget<Transform>(
    find.descendant(of: pop(), matching: find.byType(Transform)).at(1),
  );

  double opacidade(WidgetTester tester) => tester
      .widget<Opacity>(
        find.descendant(of: pop(), matching: find.byType(Opacity)).first,
      )
      .opacity;

  /// A opacidade da fala [texto] no AnimatedSwitcher.
  double fala(WidgetTester tester, String texto) => tester
      .widget<FadeTransition>(
        find
            .ancestor(
              of: find.text(texto),
              matching: find.byType(FadeTransition),
            )
            .first,
      )
      .opacity
      .value;

  testWidgets('entra do bico: 0,92 a 1 em 280 ms, subindo 8 px', (
    tester,
  ) async {
    await tester.pumpWidget(tela('Olá'));
    await tester.pump(const Duration(milliseconds: 140));
    final t = escala(tester);
    expect(t.transform.storage[0], inExclusiveRange(.92, 1));
    expect(t.alignment, AlignmentDirectional.bottomStart);
    final sobe = tester
        .widget<Transform>(
          find.descendant(of: pop(), matching: find.byType(Transform)).first,
        )
        .transform
        .getTranslation()
        .y;
    expect(sobe, inExclusiveRange(0, 8));
    await tester.pump(const Duration(milliseconds: 140));
    expect(escala(tester).transform.storage[0], 1);
    expect(opacidade(tester), 1);
  });

  testWidgets('trocar a fala: a antiga sai em 90 ms; em 300 ms só a nova', (
    tester,
  ) async {
    await tester.pumpWidget(tela('Primeira fala'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(tela('Segunda fala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    expect(fala(tester, 'Primeira fala'), inExclusiveRange(0, 1));
    expect(fala(tester, 'Segunda fala'), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 45));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Primeira fala'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Segunda fala'), findsOneWidget);
    expect(fala(tester, 'Segunda fala'), 1);
  });

  testWidgets('movimento reduzido: só fade de 100 ms, escala 1 sempre', (
    tester,
  ) async {
    await tester.pumpWidget(tela('Olá', reduzir: true));
    for (var ms = 0; ms <= 120; ms += 20) {
      final transforms = find.descendant(
        of: pop(),
        matching: find.byType(Transform),
      );
      for (final e in transforms.evaluate()) {
        expect((e.widget as Transform).transform.storage[0], 1);
      }
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(opacidade(tester), 1);
    await tester.pumpWidget(tela('Outra', reduzir: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Olá'), findsNothing);
    expect(find.text('Outra'), findsOneWidget);
  });
}
