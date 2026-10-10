import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/wiki_keys.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';
import 'package:lucena/ui/wiki/view_models/wiki_links_cubit.dart';
import 'package:lucena/ui/wiki/widgets/linked_text.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/fakes/fake_wiki.dart';
import '../../../testing/test_app.dart';

void main() {
  const bubble = Key('bubble');
  const marked =
      '{{Andersson|ulf-andersson}} played this ending in '
      '{{Skellefteå|skelleftea}}.';
  const plain = 'Andersson played this ending in Skellefteå.';
  final url = Uri.parse('https://en.wikipedia.org/wiki/Ulf_Andersson');

  Future<WikiLinksCubit> wiki() async {
    // Só o Andersson tem página: Skellefteå fica como texto normal.
    final cubit = WikiLinksCubit(
      FakeWikiLinksRepository({
        'ulf-andersson': {'en': '$url'},
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
    SpeechCubit? speech,
    String text = marked,
  }) async {
    await tester.pumpWidget(
      TestApp(
        wikiLinksCubit: links,
        webPages: pages,
        speechCubit: speech,
        child: Scaffold(
          body: TeacherSpeech(
            teacher: FakeCharacterRepository.viktor,
            text: text,
            bubbleKey: bubble,
            speechContext: SpeechContext.teaching,
            speaks: speech != null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // O primeiro nome abre a fala: o toque no começo do balão cai nele.
  Future<void> tapName(WidgetTester tester) async {
    await tester.tapAt(
      tester.getTopLeft(find.byKey(bubble)) + const Offset(12, 8),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a fala mostra só o texto visível, com o nome sublinhado', (
    tester,
  ) async {
    await pump(tester, links: await wiki());
    final text = tester.widget<Text>(find.byKey(bubble));
    expect(text.textSpan!.toPlainText(), plain);
    final spans = <TextSpan>[];
    text.textSpan!.visitChildren((span) {
      if (span is TextSpan) spans.add(span);
      return true;
    });
    final underlined = [
      for (final span in spans)
        if (span.style?.decoration == TextDecoration.underline) span.text,
    ];
    // Skellefteå não tem página: sem sublinhado.
    expect(underlined, ['Andersson']);
  });

  testWidgets('sem o mapa de links, a fala é texto normal sem a marcação', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.widget<Text>(find.byKey(bubble)).data, plain);
  });

  testWidgets('o toque no nome abre a página dentro do app e o X fecha', (
    tester,
  ) async {
    final pages = FakeWebPages();
    await pump(tester, links: await wiki(), pages: pages);
    await tapName(tester);
    expect(find.byKey(WikiKeys.sheet), findsOneWidget);
    expect(pages.opened, [url]);
    expect(find.byKey(WikiKeys.page), findsOneWidget);
    expect(find.byKey(WikiKeys.loading), findsNothing);
    expect(find.byKey(WikiKeys.offline), findsNothing);

    await tester.tap(find.byKey(WikiKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(WikiKeys.sheet), findsNothing);
    expect(find.byKey(bubble), findsOneWidget);
  });

  testWidgets('sem internet: a folha avisa e a aula segue', (tester) async {
    final pages = FakeWebPages(online: false);
    await pump(tester, links: await wiki(), pages: pages);
    await tapName(tester);
    expect(find.byKey(WikiKeys.offline), findsOneWidget);
    expect(find.text('This needs the internet'), findsOneWidget);
    expect(find.byKey(WikiKeys.page), findsNothing);

    await tester.tap(find.byKey(WikiKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(WikiKeys.sheet), findsNothing);
    expect(find.byKey(bubble), findsOneWidget);
  });

  testWidgets('a voz nunca lê a marcação nem a chave', (tester) async {
    final voice = FakeVoiceRepository(
      settings: const VoiceSettings(enabled: true),
    );
    final speech = SpeechCubit(voice);
    addTearDown(speech.close);
    await speech.load();
    await pump(tester, links: await wiki(), speech: speech);
    expect(voice.spoken, isNotEmpty);
    for (final (text, _) in voice.spoken) {
      expect(text, isNot(contains('{{')));
      expect(text, isNot(contains('ulf-andersson')));
      expect(text, contains('Andersson'));
    }
    expect(speech.state.isSpeaking(marked), isTrue);
    expect(speech.state.isSpeaking(plain), isTrue);
  });

  testWidgets('fora do balão (a história), o nome também abre a página', (
    tester,
  ) async {
    final pages = FakeWebPages();
    await tester.pumpWidget(
      TestApp(
        wikiLinksCubit: await wiki(),
        webPages: pages,
        child: const Scaffold(body: LinkedText(marked)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(plain, findRichText: true), findsOneWidget);
    await tester.tapOnText(find.textRange.ofSubstring('Andersson'));
    await tester.pumpAndSettle();
    expect(pages.opened, [url]);
    await tester.tap(find.byKey(WikiKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(WikiKeys.sheet), findsNothing);
  });
}
