import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/keys/speech_keys.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/core/widgets/script_speech_sheet.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';
import 'package:lucena/ui/free_board/widgets/character_bar.dart';
import 'package:lucena/ui/lesson_script/widgets/script_speech.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

/// T84: a fala longa no balão único, a 360×740 em PT-BR. Três estados: cabe
/// no espaço fixo de 2 linhas; se abre por cima com o X (até 4 linhas); corta
/// em "… Ver mais", que abre a folha com a fala inteira.
void main() {
  const size = Size(360, 740);
  const short = 'Vamos jogar!';
  const medium = 'Hoje eu venho com tudo, prepare a sua defesa agora.';
  final long = List.filled(
    6,
    'Esta fala comprida não cabe nem em quatro linhas do balão.',
  ).join(' ');

  void screen(WidgetTester tester) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  CharacterLine line(String text, {String id = 'fala'}) => CharacterLine(
    id: id,
    category: LineCategory.gameStart,
    intensity: 1,
    emotion: Emotion.calm,
    text: text,
  );

  Future<void> opponent(WidgetTester tester, String text, {String? id}) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 300),
              CharacterBar(
                talk: TalkState(
                  character: FakeCharacterRepository.viktor,
                  line: line(text, id: id ?? 'fala'),
                ),
                showName: false,
                playerRow: const SizedBox(height: 48),
                speechTop: -200,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  RenderParagraph paragraph(WidgetTester tester, String id) =>
      tester.renderObject<RenderParagraph>(
        find
            .descendant(
              of: find.byKey(FreeBoardKeys.speechText(id)),
              matching: find.byType(RichText),
            )
            .first,
      );

  group('adversário', () {
    testWidgets('fala curta: cabe nas 2 linhas, sem X nem "Ver mais"', (
      tester,
    ) async {
      screen(tester);
      await opponent(tester, short);
      expect(find.byKey(FreeBoardKeys.speechBubble), findsOneWidget);
      expect(find.byKey(SpeechKeys.close), findsNothing);
      expect(find.byKey(SpeechKeys.cut), findsNothing);
      final text = paragraph(tester, 'fala');
      expect(text.didExceedMaxLines, isFalse);
      expect(text.text.toPlainText(), short);
      await dispose(tester);
    });

    testWidgets('fala média: abre por cima com o X, que fecha', (tester) async {
      screen(tester);
      await opponent(tester, medium);
      expect(find.byKey(SpeechKeys.cut), findsNothing);
      final close = find.byKey(SpeechKeys.close);
      expect(close, findsOneWidget);
      // Alvo de 48 dp; o centro do X na borda de cima do balão.
      final target = tester.getSize(close);
      expect(target.width, greaterThanOrEqualTo(48));
      expect(target.height, greaterThanOrEqualTo(48));
      expect(paragraph(tester, 'fala').text.toPlainText(), medium);
      expect(paragraph(tester, 'fala').didExceedMaxLines, isFalse);

      await tester.tap(close);
      await tester.pump(const Duration(seconds: 1));
      final opacity = tester.widget<AnimatedOpacity>(
        find
            .ancestor(
              of: find.byKey(FreeBoardKeys.speechBubble),
              matching: find.byType(AnimatedOpacity),
            )
            .first,
      );
      expect(opacity.opacity, 0);
      await dispose(tester);
    });

    testWidgets('fala longa: corta em "… Ver mais", que abre a folha', (
      tester,
    ) async {
      screen(tester);
      await opponent(tester, long);
      final cut = find.byKey(SpeechKeys.cut);
      expect(cut, findsOneWidget);
      final shown = paragraph(tester, 'fala');
      expect(shown.didExceedMaxLines, isFalse);
      expect(shown.text.toPlainText(), endsWith('… Ver mais'));

      await tester.tap(cut);
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(LessonScriptKeys.speechSheet),
          matching: find.textContaining(long, findRichText: true),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(LessonScriptKeys.speechSheet),
          matching: find.byKey(VoiceKeys.speakButton),
        ),
        findsOneWidget,
      );
      await dispose(tester);
    });

    testWidgets('nenhuma fala PT é cortada sem "Ver mais"', (tester) async {
      screen(tester);
      final files = Directory('assets/lines/pt')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList();
      expect(files, isNotEmpty);
      var count = 0;
      for (final file in files) {
        final json = jsonDecode(file.readAsStringSync()) as Map;
        for (final item in (json['lines'] as List).cast<Map>()) {
          final parsed = CharacterLine.fromJson(item.cast<String, dynamic>());
          if (parsed == null) continue;
          final id = 'l${count++}';
          await opponent(tester, parsed.text, id: id);
          final shown = paragraph(tester, id);
          final plain = shown.text.toPlainText();
          final cut = find.byKey(SpeechKeys.cut).evaluate().isNotEmpty;
          expect(
            shown.didExceedMaxLines,
            isFalse,
            reason: '${file.path}: ${parsed.text}',
          );
          expect(
            cut ? plain.endsWith('… Ver mais') : plain == parsed.text,
            isTrue,
            reason: '${file.path}: ${parsed.text}',
          );
        }
      }
      expect(count, greaterThan(100));
      await dispose(tester);
    });
  });

  group('Viktor', () {
    Future<void> viktor(WidgetTester tester, String text) async {
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: Builder(
                builder: (context) => ScriptSpeech(
                  texts: [text],
                  metrics: ScriptSpeechMetrics.of(context),
                  onOpen: () => showScriptSpeechSheet(
                    context,
                    viktor: FakeCharacterRepository.viktor,
                    title: FakeCharacterRepository.viktor.name,
                    texts: [text],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('fala curta: inteira no balão, sem "Ver mais"', (tester) async {
      screen(tester);
      await viktor(tester, short);
      expect(find.byKey(SpeechKeys.cut), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(LessonScriptKeys.speech),
          matching: find.textContaining(short, findRichText: true),
        ),
        findsOneWidget,
      );
    });

    testWidgets('fala longa: a área fixa não cresce; "Ver mais" abre a folha', (
      tester,
    ) async {
      screen(tester);
      await viktor(tester, short);
      final area = tester.getSize(find.byType(ScriptSpeech));
      await viktor(tester, long);
      expect(tester.getSize(find.byType(ScriptSpeech)), area);
      final cut = find.byKey(SpeechKeys.cut);
      expect(cut, findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(cut).text.toPlainText(),
        endsWith('… Ver mais'),
      );

      await tester.tap(cut);
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.speechSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(LessonScriptKeys.speechSheet),
          matching: find.textContaining(long, findRichText: true),
        ),
        findsOneWidget,
      );
    });
  });
}
