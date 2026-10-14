import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
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

    expect(await fontOf('Uma fala curta.'), 16);
    // Na fonte dos testes cada letra é um quadrado: 25 palavras de 3 letras
    // dão 5 linhas em 16 sp e cabem em 4 com a letra um pouco menor.
    final fitted = await fontOf(List.filled(25, 'abc').join(' '));
    expect(fitted, lessThan(15));
    expect(fitted, greaterThanOrEqualTo(ScriptSpeechMetrics.minFontSize));
    // Com a letra menor, a fala cabe em 4 linhas.
    final lines =
        (tester.getSize(find.byKey(LessonScriptKeys.speech)).height -
            2 * 14 -
            SpeechBalloon.tailHeight) /
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
      SpeechText.plain(
        'Clique em {linhaPrincipal}.',
        mainLine: 'Ver linha principal',
        showAnswer: 'Ver resposta',
      ),
      'Clique em Ver linha principal',
    );
  });

  testWidgets('Ver resposta na fala: link sem o ponto colado; o clique faz o '
      'mesmo que o botão; o balão abre a fala inteira', (tester) async {
    var answers = 0;
    var opens = 0;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: Builder(
            builder: (context) => ScriptSpeech(
              texts: const ['Pense e clique em {verResposta}.'],
              metrics: ScriptSpeechMetrics.of(context),
              onShowAnswer: () => answers++,
              onOpen: () => opens++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('{verResposta}'), findsNothing);
    expect(find.textContaining('Ver resposta.'), findsNothing);
    final rich = tester.widget<Text>(
      find.descendant(
        of: find.byKey(LessonScriptKeys.speech),
        matching: find.byType(Text),
      ),
    );
    final link = (rich.textSpan! as TextSpan).children!
        .whereType<TextSpan>()
        .firstWhere((span) => span.text == 'Ver resposta');
    expect(link.style?.decoration, TextDecoration.underline);
    await tester.tapOnText(find.textRange.ofSubstring('Ver resposta'));
    expect(answers, 1);
    expect(opens, 0);
    // Fora do link, o balão inteiro abre a fala.
    await tester.tapOnText(find.textRange.ofSubstring('Pense'));
    expect(opens, 1);
  });

  testWidgets('sem ação, a marca vira texto sublinhado sem clique', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: const Scaffold(
          body: SpeechText(
            text: 'Clique em {linhaPrincipal}. Depois siga.',
            style: TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
    final rich = tester.widget<Text>(find.byType(Text));
    expect(
      rich.textSpan!.toPlainText(),
      'Clique em Ver linha principal Depois siga.',
    );
    final link = (rich.textSpan! as TextSpan).children![1] as TextSpan;
    expect(link.recognizer, isNull);
  });

  group('corte com link (T71, opção C)', () {
    const fim =
        'O rei preto alcançou o peão e o capturou, e sem o peão não '
        'há como ganhar esta posição. ';
    const convite = 'Clique em {linhaPrincipal} e eu lhe mostro.';
    var lines = 0;

    Future<void> pump(WidgetTester tester, String text) async {
      tester.view
        ..physicalSize = const Size(900, 400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: Scaffold(
            body: SizedBox(
              // A letra de teste tem 16 de largura: 50 letras por linha.
              width: 800,
              child: SpeechText(
                text: text,
                style: const TextStyle(fontSize: 16, height: 1.5),
                maxLines: 2,
                onMainLine: () => lines++,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('o corte vai para o meio e a última linha é a do link', (
      tester,
    ) async {
      lines = 0;
      await pump(tester, fim + convite);
      final texts = tester.widgetList<Text>(find.byType(Text)).toList();
      expect(texts, hasLength(2));
      expect(texts.first.maxLines, 1);
      expect(texts.first.overflow, TextOverflow.ellipsis);
      expect(
        texts.last.textSpan!.toPlainText(),
        'Clique em Ver linha principal e eu lhe mostro.',
      );
      // A frase do link cabe inteira na última linha.
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byWidget(texts.last),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      // As duas linhas somam a altura de 2 linhas de 24.
      expect(tester.getSize(find.byType(SpeechText)).height, 48);
      final link = find.textRange.ofSubstring('Ver linha principal');
      expect(link, findsOneWidget);
      await tester.tapOnText(link);
      expect(lines, 1);
    });

    testWidgets('sem corte, o texto fica inteiro e corrido', (tester) async {
      await pump(tester, 'Agora sim. $convite');
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('corte sem link: reticências no fim, como antes', (
      tester,
    ) async {
      await pump(tester, fim + fim);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });
}
