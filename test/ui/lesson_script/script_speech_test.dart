import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';

import '../../../testing/test_app.dart';

Future<void> _pump(WidgetTester tester, {required bool typing}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ScriptSpeech(
              texts: const ['Uma fala que ocupa a largura do balão.'],
              metrics: ScriptSpeechMetrics.of(context),
              typing: typing,
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('pensando: pontinhos no lugar da fala, com a mesma altura', (
    tester,
  ) async {
    await _pump(tester, typing: false);
    await tester.pumpAndSettle();
    final height = tester.getSize(find.byKey(LessonScriptKeys.speech)).height;
    expect(find.byKey(LessonScriptKeys.typing), findsNothing);

    await _pump(tester, typing: true);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(LessonScriptKeys.typing), findsOneWidget);
    // A fala fica invisível, mas segura a altura: o tabuleiro não pula.
    expect(tester.getSize(find.byKey(LessonScriptKeys.speech)).height, height);
    final text = find.text('Uma fala que ocupa a largura do balão.');
    expect(
      tester
          .widget<Visibility>(
            find.ancestor(of: text, matching: find.byType(Visibility)),
          )
          .visible,
      isFalse,
    );
    // O balão dos pontinhos é pequeno, com folga dos lados.
    final dots = tester.getSize(
      find
          .ancestor(
            of: find.byKey(LessonScriptKeys.typing),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(dots.width, inInclusiveRange(80, 120));
    expect(dots.height, lessThan(height));
  });

  testWidgets('fala longa: a letra diminui até caber em 4 linhas', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<double> fontOf(String text) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Numa coluna, como na tela: a altura é a do texto.
            body: Builder(
              builder: (context) => Column(
                children: [
                  ScriptSpeech(
                    texts: [text],
                    metrics: ScriptSpeechMetrics.of(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(LessonScriptKeys.speech),
              matching: find.byType(Text),
            ),
          )
          .style!
          .fontSize!;
    }

    expect(await fontOf('Uma fala curta.'), 15);
    // Na fonte dos testes cada letra é um quadrado: 25 palavras de 3 letras
    // dão 5 linhas em 15 sp e cabem em 4 com a letra um pouco menor.
    final fitted = await fontOf(List.filled(25, 'abc').join(' '));
    expect(fitted, lessThan(15));
    expect(fitted, greaterThanOrEqualTo(ScriptSpeechMetrics.minFontSize));
    // Com a letra menor, a fala cabe em 4 linhas.
    final lines =
        (tester.getSize(find.byKey(LessonScriptKeys.speech)).height - 2 * 14) /
        (fitted * ScriptSpeechMetrics.lineHeight);
    expect(lines, lessThan(4.5));
  });

  testWidgets('Ver linha principal na fala: sublinhado, clique faz o mesmo '
      'que o botão', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: Builder(
            builder: (context) => ScriptSpeech(
              texts: const ['Clique em {linhaPrincipal} e eu lhe mostro.'],
              metrics: ScriptSpeechMetrics.of(context),
              onMainLine: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('{linhaPrincipal}'), findsNothing);
    final link = find.textRange.ofSubstring('Ver linha principal');
    expect(link, findsOneWidget);
    await tester.tapOnText(link);
    expect(taps, 1);
    expect(
      ScriptSpeech.plain('Clique em {linhaPrincipal}.', 'Ver linha principal'),
      'Clique em Ver linha principal.',
    );
  });
}
