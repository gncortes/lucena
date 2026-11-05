import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/external_page_keys.dart';
import 'package:lucena/ui/core/widgets/speech_balloon.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';
import 'package:lucena/ui/wiki/view_models/wiki_links_cubit.dart';

import '../../../../testing/fakes/fake_wiki.dart';
import '../../../../testing/test_app.dart';

// T85: as falas do Pilares marcam os jogadores com {{nome|chave}}. A lição
// roteirizada desenha a fala pelo SpeechText, que mostrava a marcação crua.
void main() {
  const fala =
      'Paris, 1858. {{Paul Morphy|paul-morphy}}, de brancas, enfrentou o '
      '{{duque de Brunswick|charles-ii-duke-of-brunswick}} e o conde Isouard.';
  const limpa =
      'Paris, 1858. Paul Morphy, de brancas, enfrentou o '
      'duque de Brunswick e o conde Isouard.';
  final morphy = Uri.parse('https://pt.wikipedia.org/wiki/Paul_Morphy');

  Future<WikiLinksCubit> wiki() async {
    final cubit = WikiLinksCubit(
      FakeWikiLinksRepository({
        'paul-morphy': {'pt': '$morphy'},
        'charles-ii-duke-of-brunswick': {
          'pt': 'https://pt.wikipedia.org/wiki/Carlos_II_de_Brunswick',
        },
      }),
    );
    await cubit.load();
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> pump(
    WidgetTester tester, {
    WikiLinksCubit? links,
    FakeWebPages? pages,
  }) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        wikiLinksCubit: links,
        webPages: pages,
        child: const Scaffold(
          body: SpeechText(text: fala, style: TextStyle(fontSize: 16)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  List<TextSpan> spans(WidgetTester tester) {
    final out = <TextSpan>[];
    for (final rich in tester.widgetList<RichText>(
      find.descendant(
        of: find.byType(SpeechText),
        matching: find.byType(RichText),
      ),
    )) {
      rich.text.visitChildren((span) {
        if (span is TextSpan) out.add(span);
        return true;
      });
    }
    return out;
  }

  String shown(WidgetTester tester) => tester
      .widgetList<RichText>(
        find.descendant(
          of: find.byType(SpeechText),
          matching: find.byType(RichText),
        ),
      )
      .map((r) => r.text.toPlainText())
      .join()
      .replaceAll('‑', '-');

  testWidgets('os nomes saem sublinhados, sem a marcação', (tester) async {
    await pump(tester, links: await wiki());
    expect(shown(tester), limpa);
    final underlined = [
      for (final span in spans(tester))
        if (span.style?.decoration == TextDecoration.underline &&
            span.recognizer is TapGestureRecognizer)
          span.text,
    ];
    expect(underlined, ['Paul Morphy', 'duque de Brunswick']);
  });

  testWidgets('sem o mapa de links, os nomes ficam como texto normal', (
    tester,
  ) async {
    await pump(tester);
    expect(shown(tester), limpa);
  });

  testWidgets('o toque no nome abre a página dentro do app', (tester) async {
    final pages = FakeWebPages();
    await pump(tester, links: await wiki(), pages: pages);
    await tester.tapOnText(find.textRange.ofSubstring('Paul Morphy'));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsOneWidget);
    expect(pages.opened, [morphy]);
  });

  test('a voz e a medida usam o texto limpo', () {
    expect(SpeechText.plain(fala, mainLine: 'x', showAnswer: 'y'), limpa);
  });

  test('o corte da fala do canvas não parte a marcação', () {
    final fitted = CanvasSpeechLayout.fit(text: fala, width: 160, lines: 2);
    expect(fitted.truncated, isTrue);
    final opened = '{{'.allMatches(fitted.text).length;
    final closed = '}}'.allMatches(fitted.text).length;
    expect(opened, closed);
    expect(fitted.text, isNot(contains('}}}')));
  });
}
