import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena/ui/core/widgets/viktor_sheet.dart';
import 'package:lucena/ui/core/keys/viktor_sheet_keys.dart';
import 'package:lucena/ui/core/keys/explanation_keys.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_voice_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

import 'package:lucena/data/repositories/voice/voice_repository.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/core/keys/voice_keys.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

class _DelayedVoiceRepository extends FakeVoiceRepository {
  _DelayedVoiceRepository()
    : super(settings: const VoiceSettings(enabled: false));
  final saved = Completer<void>();

  @override
  Future<void> save(VoiceSettings settings) async {
    await saved.future;
    await super.save(settings);
  }
}

void main() {
  testWidgets(
    'editorial text direction preserves fallback SAN and Arabic links',
    (tester) async {
      const key = Key('directional-editorial');
      const lri = '\u2066';
      const pdi = '\u2069';
      for (final typed in [false, true]) {
        for (final (text, direction, moves) in [
          (
            '1.Ke3 allows a draw and does not meet the goal.',
            TextDirection.ltr,
            ['1.Ke3'],
          ),
          (
            'النقلة 1.Ke3 تحافظ على الوضع بعد 12 نقلة.',
            TextDirection.rtl,
            ['1.Ke3'],
          ),
          (
            'بعد 1...Rh7 يلعب الأبيض Kxe3+ ثم 2.Rd7 ويفوز.',
            TextDirection.rtl,
            ['1...Rh7', 'Kxe3+', '2.Rd7'],
          ),
        ]) {
          for (final move in moves) {
            final tapped = <String>[];
            await tester.pumpWidget(
              TestApp(
                locale: const Locale('ar'),
                child: Scaffold(
                  body: TeacherSpeech(
                    teacher: FakeCharacterRepository.viktor,
                    text: null,
                    bubbleKey: key,
                    typed: typed,
                    speechContext: SpeechContext.teaching,
                    lessonV2: true,
                    onLink: (link) => tapped.add('${link.start}:${link.text}'),
                    explanation: ExplanationPayload(
                      positionId: 'direction',
                      state: ExplanationState.incorrect,
                      explanations: [
                        ExplanationBlock(
                          id: 'played',
                          kind: ExplanationKind.playedIncorrect,
                          texts: [text],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final rich = find.descendant(
              of: find.byKey(key),
              matching: find.byType(RichText),
            );
            final paragraph = tester.renderObject<RenderParagraph>(rich);
            final drawn = paragraph.text.toPlainText();
            // The source text is drawn whole; only isolates are added.
            expect(drawn.replaceAll(lri, '').replaceAll(pdi, ''), text);
            if (direction == TextDirection.ltr) {
              expect(drawn, text, reason: 'LTR paragraphs need no isolates');
            } else {
              for (final notation in moves) {
                expect(drawn, contains('$lri$notation$pdi'));
              }
            }
            expect(paragraph.textDirection, direction);
            expect(
              Directionality.of(tester.element(find.byType(TeacherSpeech))),
              TextDirection.rtl,
            );
            // Boxes are measured in the drawn text; the tap reports the
            // offset of the source text.
            final drawnOffset = drawn.indexOf(move);
            final boxes = [
              for (var i = 0; i < move.length; i++)
                paragraph
                    .getBoxesForSelection(
                      TextSelection(
                        baseOffset: drawnOffset + i,
                        extentOffset: drawnOffset + i + 1,
                      ),
                    )
                    .single,
            ];
            // The whole notation runs left to right, number attached.
            for (var i = 1; i < boxes.length; i++) {
              expect(
                boxes[i].left,
                greaterThanOrEqualTo(boxes[i - 1].right - .1),
                reason: '$move char $i in "$text"',
              );
            }
            final san = boxes[move.length ~/ 2];
            await tester.tapAt(
              paragraph.localToGlobal(
                Offset((san.left + san.right) / 2, (san.top + san.bottom) / 2),
              ),
            );
            expect(tapped, ['${text.indexOf(move)}:$move']);
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );
  testWidgets('RTL isolates leave Semantics with the source text', (
    tester,
  ) async {
    const text = 'النقلة 1.Ke3 تحافظ على الوضع.';
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('ar'),
        child: Scaffold(
          body: TeacherSpeech(
            teacher: FakeCharacterRepository.viktor,
            text: text,
            speechContext: SpeechContext.teaching,
            lessonV2: true,
            onLink: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final labels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .map((widget) => widget.properties.label ?? '')
        .where((label) => label.contains('1.Ke3'));
    expect(labels, isNotEmpty);
    for (final label in labels) {
      expect(label, isNot(contains('\u2066')));
      expect(label, contains(text));
    }
    handle.dispose();
  });
  for (final (available, enabled) in [
    (true, false),
    (true, true),
    (false, false),
  ]) {
    testWidgets(
      'V2 panel and badge fit with voice=$enabled, TTS=$available, RTL and enlarged text',
      (tester) async {
        final voice = FakeVoiceRepository(
          settings: VoiceSettings(enabled: enabled),
          voices: available ? null : [],
        );
        final speech = SpeechCubit(voice);
        addTearDown(speech.close);
        await speech.load();
        var opened = 0;
        await tester.pumpWidget(
          TestApp(
            speechCubit: speech,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: MediaQuery(
                    data: const MediaQueryData(
                      textScaler: TextScaler.linear(2),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: TeacherSpeech(
                        teacher: FakeCharacterRepository.viktor,
                        text: 'The panel remains available.',
                        speechContext: SpeechContext.teaching,
                        part: TeacherSpeechPart.header,
                        lessonV2: true,
                        onSoundSettings: () => opened++,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byKey(VoiceKeys.speedButton), findsNothing);
        expect(
          find.text('1×'),
          available && enabled ? findsOneWidget : findsNothing,
        );
        if (available && enabled) {
          final label = tester.renderObject<RenderParagraph>(find.text('1×'));
          final boxes = label.getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 2),
          );
          expect(boxes, isNotEmpty);
          for (final box in boxes) {
            expect(box.top, greaterThanOrEqualTo(0));
            expect(box.bottom, lessThanOrEqualTo(label.size.height));
          }
          expect(label.size.height, lessThanOrEqualTo(16));
        }
        await tester.tap(find.byKey(VoiceKeys.speakButton));
        await tester.pump();
        expect(opened, 1);
        expect(voice.spoken, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'mute during delayed voice preference save prevents manual playback',
    (tester) async {
      final voice = _DelayedVoiceRepository();
      final speech = SpeechCubit(voice);
      final settings = SettingsCubit(
        FakeSettingsRepository(const AppSettings()),
        languages: AppLanguage.selectable,
      );
      addTearDown(speech.close);
      addTearDown(settings.close);
      await speech.load();
      await settings.load();
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: 'The teacher must stay muted.',
              speechContext: SpeechContext.teaching,
              speaks: true,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(VoiceKeys.speakButton));
      await settings.setSound(enabled: false);
      await tester.pump();
      voice.saved.complete();
      await tester.pump();
      await tester.pump();
      expect(voice.spoken, isEmpty);
      expect(speech.state.speaking, isNull);
      expect(voice.settings.enabled, isTrue);
    },
  );

  testWidgets(
    'V2 sound button opens settings; general mute gates current and future teacher speech',
    (tester) async {
      final voice = FakeVoiceRepository(
        settings: const VoiceSettings(enabled: true, charactersMuted: true),
      );
      final speech = SpeechCubit(voice);
      final settings = SettingsCubit(
        FakeSettingsRepository(const AppSettings()),
        languages: AppLanguage.selectable,
      );
      final text = ValueNotifier('First teaching sentence.');
      addTearDown(text.dispose);
      addTearDown(speech.close);
      addTearDown(settings.close);
      await speech.load();
      await settings.load();
      var opened = 0;
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          speechCubit: speech,
          child: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: text,
              builder: (_, value, _) => TeacherSpeech(
                teacher: FakeCharacterRepository.viktor,
                text: value,
                speechContext: SpeechContext.teaching,
                lessonV2: true,
                speaks: true,
                onSoundSettings: () => opened++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(voice.spoken, hasLength(1));
      expect(find.byKey(VoiceKeys.speedButton), findsNothing);
      expect(find.text('1×'), findsOneWidget);
      expect(find.byTooltip('Sound and voice: on, speed 1×'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(VoiceKeys.speakButton)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byKey(VoiceKeys.speakButton));
      await tester.pump();
      expect(opened, 1);
      expect(voice.spoken, hasLength(1));
      await settings.setSound(enabled: false);
      await tester.pump();
      expect(speech.state.speaking, isNull);
      expect(find.text('1×'), findsNothing);
      expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
      expect(find.byTooltip('Sound and voice: off'), findsOneWidget);
      text.value = 'Next teaching sentence while muted.';
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(VoiceKeys.speakButton));
      await tester.pump();
      expect(opened, 2);
      expect(voice.spoken, hasLength(1));
      expect(voice.settings.enabled, isTrue);
      expect(voice.settings.charactersMuted, isTrue);
      await settings.setSound(enabled: true);
      await tester.pump();
      expect(voice.spoken, hasLength(1));
      text.value = 'A new sentence after unmuting.';
      await tester.pump();
      await tester.pump();
      expect(voice.spoken, hasLength(2));
      expect(voice.settings.enabled, isTrue);
      expect(voice.settings.charactersMuted, isTrue);
    },
  );

  testWidgets('muted teacher does not autoplay initially or play manually', (
    tester,
  ) async {
    final voice = FakeVoiceRepository(
      settings: const VoiceSettings(enabled: true),
    );
    final speech = SpeechCubit(voice);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings(sound: false)),
      languages: AppLanguage.selectable,
    );
    addTearDown(speech.close);
    addTearDown(settings.close);
    await speech.load();
    await settings.load();
    Future<void> show({required bool auto}) async {
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: 'Muted teacher sentence.',
              speechContext: SpeechContext.teaching,
              speaks: auto,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(VoiceKeys.speakButton), warnIfMissed: false);
      await tester.pump();
    }

    await show(auto: true);
    await show(auto: false);
    expect(voice.spoken, isEmpty);
    expect(voice.settings.enabled, isTrue);
  });

  testWidgets(
    'V2 paragraphs keep an eight pixel gap and supplied quality colors',
    (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: 'First paragraph.\n\n1.Kh2? Second paragraph.',
              speechContext: SpeechContext.teaching,
              lessonV2: true,
              onLink: (_) {},
            ),
          ),
        ),
      );
      final rich = find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText() ==
                'First paragraph.\n\n1.Kh2? Second paragraph.',
      );
      final paragraph = tester.renderObject<RenderParagraph>(rich);
      final first = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 16),
          )
          .first;
      final second = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 18, extentOffset: 24),
          )
          .first;
      // Compare line positions: a 24px line box plus the 8px paragraph gap.
      expect(second.top - first.top, closeTo(32, 0.1));
      TextSpan? move;
      tester.widget<RichText>(rich).text.visitChildren((span) {
        if (span is TextSpan && span.text == '1.Kh2?') move = span;
        return true;
      });
      expect(move?.style?.color, const Color(0xFFC2410C));
    },
  );
  testWidgets('V2 highlights repeated SAN only at its own origin', (
    tester,
  ) async {
    ExplanationVariation line(String id, String fen, String text) =>
        ExplanationVariation(
          id: id,
          label: id,
          outcome: VariationOutcome.accepted,
          texts: [text],
          originFen: fen,
          movesUci: const ['h1h2'],
          movesSan: const ['1.Kh2'],
          validated: true,
        );
    final a = line('A', '6k1/8/8/8/8/8/3P4/7K w - - 0 1', 'First: 1.Kh2.');
    final b = line('B', '5k2/8/8/8/8/8/3P4/7K w - - 0 1', 'Second: 1.Kh2.');
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: TeacherSpeech(
            teacher: FakeCharacterRepository.viktor,
            text: null,
            speechContext: SpeechContext.teaching,
            lessonV2: true,
            activeVariation: a.open(),
            onVariation: (_) {},
            explanation: ExplanationPayload(
              positionId: 'repeated-san',
              state: ExplanationState.review,
              explanations: [
                for (final variation in [a, b])
                  ExplanationBlock(
                    id: variation.id,
                    kind: ExplanationKind.mainSolution,
                    texts: variation.texts,
                    variations: [variation],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Color? background(String paragraph) {
      final rich = tester
          .widgetList<RichText>(find.byType(RichText))
          .singleWhere((widget) => widget.text.toPlainText() == paragraph);
      TextSpan? move;
      rich.text.visitChildren((span) {
        if (span is TextSpan && (span.text?.contains('Kh2') ?? false)) {
          move = span;
        }
        return true;
      });
      expect(move, isNotNull);
      return move!.style?.backgroundColor;
    }

    expect(background('First: 1.Kh2.'), isNotNull);
    expect(background('Second: 1.Kh2.'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'editorial opening emphasizes prose without changing SAN or prompt',
    (tester) async {
      const text = 'Before 1.Kh2 after.\n\nSecond paragraph.';
      for (final prompt in [false, true]) {
        await tester.pumpWidget(
          TestApp(
            child: Scaffold(
              body: TeacherSpeech(
                teacher: FakeCharacterRepository.viktor,
                text: null,
                speechContext: SpeechContext.teaching,
                lessonV2: true,
                lessonPromptBubble: prompt,
                onLink: (_) {},
                explanation: ExplanationPayload(
                  positionId: 'opening',
                  state: ExplanationState.incorrect,
                  explanations: [
                    ExplanationBlock(
                      id: 'played',
                      kind: ExplanationKind.playedIncorrect,
                      texts: const ['Before 1.Kh2 after.', 'Second paragraph.'],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final rich = tester
            .widgetList<RichText>(find.byType(RichText))
            .singleWhere((widget) => widget.text.toPlainText() == text);
        final pieces = <String, FontWeight?>{};
        rich.text.visitChildren((span) {
          if (span is TextSpan && span.text != null) {
            pieces[span.text!] = span.style?.fontWeight;
          }
          return true;
        });
        expect(pieces['Before '], prompt ? isNull : FontWeight.w500);
        expect(pieces[' after.'], prompt ? isNull : FontWeight.w500);
        expect(pieces['Second paragraph.'], isNull);
        expect(pieces['1.Kh2'], FontWeight.w700);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'one bubble joins paragraphs and verified inline move replaces SAN button',
    (tester) async {
      final main = ExplanationVariation(
        id: 'main',
        label: '1.Kh2',
        outcome: VariationOutcome.accepted,
        texts: const ['First: 1.Kh2.', 'Second paragraph.'],
        originFen: '6k1/8/8/8/8/8/3P4/7K w - - 0 1',
        movesUci: const ['h1h2'],
        movesSan: const ['1.Kh2'],
        validated: true,
      );
      final fallback = ExplanationVariation(
        id: 'fallback',
        label: '1.Kh2',
        outcome: VariationOutcome.accepted,
        texts: const ['Unlinked explanation.'],
        originFen: main.originFen,
        movesUci: main.movesUci,
        movesSan: main.movesSan,
        validated: true,
      );
      VariationCursor? selected;
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: null,
              speechContext: SpeechContext.teaching,
              explanation: ExplanationPayload(
                positionId: 'p',
                state: ExplanationState.review,
                explanations: [
                  ExplanationBlock(
                    id: 'main',
                    kind: ExplanationKind.mainSolution,
                    texts: main.texts,
                    variations: [main],
                  ),
                  ExplanationBlock(
                    id: 'fallback',
                    kind: ExplanationKind.otherSolutions,
                    variations: [fallback],
                  ),
                ],
              ),
              onVariation: (cursor) => selected = cursor,
              onLink: (_) =>
                  fail('The inline move must open its verified origin.'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ExplanationKeys.variation('main')), findsNothing);
      final paragraph = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere(
            (widget) =>
                widget.properties.label?.contains(
                  'First: 1.Kh2.\n\nSecond paragraph.',
                ) ??
                false,
          );
      expect(paragraph.properties.customSemanticsActions, hasLength(1));
      paragraph.properties.customSemanticsActions!.values.single.call();
      expect(selected!.variation.id, 'main');
      expect(selected!.fen, main.open()!.fen);
      expect(find.byKey(ExplanationKeys.variation('fallback')), findsOneWidget);
      await tester.tap(find.byKey(ExplanationKeys.variation('fallback')));
      await tester.pumpAndSettle();
      expect(selected!.variation.id, 'fallback');
      expect(
        find.text('Unlinked explanation.', findRichText: true),
        findsOneWidget,
      );
    },
  );
  testWidgets('branch notation validates against the complete parent graph', (
    tester,
  ) async {
    final root = ExplanationVariation(
      id: 'A',
      label: 'A',
      outcome: VariationOutcome.accepted,
      texts: const ['First: 1.d4.'],
      originFen: '6k1/8/8/8/8/8/3P4/7K w - - 0 1',
      movesUci: const ['d2d4'],
      movesSan: const ['1.d4'],
      validated: true,
    );
    final child = ExplanationVariation(
      id: 'A.1',
      label: 'A.1',
      parentId: 'A',
      parentPly: 1,
      outcome: VariationOutcome.accepted,
      texts: const ['Reply: 1...Kf7.'],
      originFen: root.open()!.fen,
      movesUci: const ['g8f7'],
      movesSan: const ['1...Kf7'],
      validated: true,
    );
    final payload = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.review,
      explanations: [
        ExplanationBlock(
          id: 'tree',
          kind: ExplanationKind.mainSolution,
          variations: [root, child],
        ),
      ],
    );
    VariationCursor? selected;
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            child: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: null,
              speechContext: SpeechContext.teaching,
              explanation: payload,
              activeVariation: payload.openVariation(child),
              onVariation: (cursor) => selected = cursor,
              onLink: (_) =>
                  fail('A verified child link must keep its ancestry.'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .singleWhere(
          (w) => w.properties.label?.contains('Reply: 1...Kf7.') ?? false,
        );
    paragraph.properties.customSemanticsActions!.values.single.call();
    expect(selected!.variation.id, 'A.1');
    expect(selected!.fen, payload.openVariation(child)!.fen);
    expect(
      payload.cursorForNotation(
        '1.d4',
        preferred: child,
        strictPreferred: true,
      ),
      isNull,
    );
  });
  testWidgets(
    'a notation link keeps its paragraph origin while another line is active',
    (tester) async {
      ExplanationVariation line(String id, String first) =>
          ExplanationVariation(
            id: id,
            label: '1...Kf7',
            outcome: VariationOutcome.accepted,
            texts: ['$id: 1...Kf7.'],
            originFen: '6k1/8/8/8/8/8/3P4/7K w - - 0 1',
            movesUci: [first, 'g8f7'],
            movesSan: ['1.${first == 'd2d4' ? 'd4' : 'd3'}', '1...Kf7'],
            validated: true,
          );
      final main = line('main', 'd2d4');
      final other = line('other', 'd2d3');
      VariationCursor? selected;
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: SingleChildScrollView(
              child: TeacherSpeech(
                teacher: FakeCharacterRepository.viktor,
                text: null,
                speechContext: SpeechContext.teaching,
                explanation: ExplanationPayload(
                  positionId: 'p',
                  state: ExplanationState.review,
                  explanations: [
                    ExplanationBlock(
                      id: 'main',
                      kind: ExplanationKind.mainSolution,
                      texts: main.texts,
                      variations: [main],
                    ),
                    ExplanationBlock(
                      id: 'other',
                      kind: ExplanationKind.otherSolutions,
                      variations: [other],
                    ),
                  ],
                ),
                activeVariation: other.open(),
                onVariation: (cursor) => selected = cursor,
                onLink: (_) => fail(
                  'The scoped notation must open its own verified line.',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ExplanationKeys.variation('main')), findsNothing);
      final paragraph = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .singleWhere(
            (widget) =>
                widget.properties.label?.contains('main: 1...Kf7.') ?? false,
          );
      paragraph.properties.customSemanticsActions!.values.single.call();
      expect(selected!.variation.id, 'main');
      expect(selected!.ply, 2);
      expect(selected!.fen, main.open()!.at(2).fen);
      expect(selected!.fen, isNot(other.open()!.at(2).fen));
    },
  );
  const speech = Key('speech');
  const speech_ = speech;
  const long =
      'Queen against rook is a win, but the queen cannot do it alone: a rook '
      'glued to its king defends everything.';

  Future<void> pump(
    WidgetTester tester, {
    SpeechContext speechContext = SpeechContext.game,
    bool typed = false,
    bool noAnimations = false,
  }) => tester.pumpWidget(
    TestApp(
      child: MediaQuery(
        data: MediaQueryData(disableAnimations: noAnimations),
        child: Scaffold(
          body: TeacherSpeech(
            teacher: FakeCharacterRepository.viktor,
            text: long,
            bubbleKey: speech,
            speechContext: speechContext,
            typed: typed,
          ),
        ),
      ),
    ),
  );

  String shown(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(speech)).data!;

  testWidgets(
    'folha compacta: avatar e texto juntos, controles completos no modal',
    (tester) async {
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: ViktorSheet(
              top: 400,
              children: [
                TeacherSpeech(
                  teacher: FakeCharacterRepository.viktor,
                  text: long,
                  speechContext: SpeechContext.teaching,
                  compactInSheet: true,
                  bubbleKey: speech,
                  headerAction: const Icon(Icons.layers, key: Key('marks')),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final avatar = tester.getRect(find.byType(CharacterAvatar));
      final words = tester.getRect(find.byKey(speech));
      expect(avatar.width, 32);
      expect(words.left, greaterThan(avatar.right));
      expect(words.top - avatar.top, lessThan(12));
      expect(find.byKey(const Key('marks')), findsNothing);
      final fontSize = tester.widget<Text>(find.byKey(speech)).style!.fontSize;
      await tester.tapAt(
        tester.getTopLeft(find.byKey(ViktorSheetKeys.scroll)) +
            const Offset(40, 12),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('marks')).hitTestable(), findsOneWidget);
      expect(tester.getRect(find.byType(CharacterAvatar)).width, 64);
      expect(tester.widget<Text>(find.byKey(speech)).style!.fontSize, fontSize);
      expect(shown(tester), long);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ao lado: o balão começa à direita do retrato', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    final avatar = tester.getRect(find.byType(CharacterAvatar));
    final text = tester.getRect(find.byKey(speech));
    expect(text.left, greaterThan(avatar.right));
  });

  testWidgets('embaixo: o balão fica abaixo do retrato e usa a largura toda', (
    tester,
  ) async {
    await pump(tester, speechContext: SpeechContext.teaching);
    await tester.pumpAndSettle();
    final avatar = tester.getRect(find.byType(CharacterAvatar));
    final text = tester.getRect(find.byKey(speech));
    expect(text.top, greaterThan(avatar.bottom));
    expect(text.left, lessThan(avatar.right));
  });

  testWidgets('a fala aparece aos poucos e o texto está inteiro desde o '
      'começo', (tester) async {
    await pump(tester, speechContext: SpeechContext.teaching, typed: true);
    await tester.pump(const Duration(milliseconds: 100));
    // O texto inteiro já está lá (quem lê a tela ouve tudo); só a vista é
    // recortada enquanto a fala anda.
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsOneWidget);

    await tester.pumpAndSettle();
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('um toque no balão mostra a fala inteira', (tester) async {
    await pump(tester, speechContext: SpeechContext.teaching, typed: true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ClipPath), findsOneWidget);

    // O texto ainda está recortado: quem recebe o toque é a área da fala.
    await tester.tap(find.byKey(speech), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('com as animações desligadas a fala aparece de uma vez', (
    tester,
  ) async {
    await pump(
      tester,
      speechContext: SpeechContext.teaching,
      typed: true,
      noAnimations: true,
    );
    await tester.pump();
    expect(shown(tester), long);
    expect(find.byType(ClipPath), findsNothing);
  });

  testWidgets('a fala longa cresce o balão, sem rolagem dentro dele', (
    tester,
  ) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(TeacherSpeech),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
  });

  testWidgets('fala nova com o começo fora da tela: a tela rola até ele', (
    tester,
  ) async {
    final text = ValueNotifier(long);
    final controller = ScrollController();
    addTearDown(text.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 300),
                ValueListenableBuilder(
                  valueListenable: text,
                  builder: (context, value, _) => TeacherSpeech(
                    speechContext: SpeechContext.game,
                    teacher: FakeCharacterRepository.viktor,
                    text: value,
                    bubbleKey: speech,
                  ),
                ),
                const SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(1500);
    await tester.pump();

    text.value = 'Now the next step.';
    await tester.pumpAndSettle();
    final top = tester.getRect(find.byType(TeacherSpeech)).top;
    expect(top, greaterThanOrEqualTo(0));
    expect(controller.offset, lessThan(400));
  });

  testWidgets('fala nova à vista: a tela não se mexe', (tester) async {
    final text = ValueNotifier(long);
    final controller = ScrollController();
    addTearDown(text.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            controller: controller,
            child: Column(
              children: [
                const SizedBox(height: 300),
                ValueListenableBuilder(
                  valueListenable: text,
                  builder: (context, value, _) => TeacherSpeech(
                    speechContext: SpeechContext.game,
                    teacher: FakeCharacterRepository.viktor,
                    text: value,
                    bubbleKey: speech,
                  ),
                ),
                const SizedBox(height: 3000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(100);
    await tester.pump();

    text.value = 'Now the next step.';
    await tester.pumpAndSettle();
    expect(controller.offset, 100);
  });

  group('com a voz', () {
    Future<(SpeechCubit, FakeVoiceRepository)> pumpWithVoice(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      final voice = FakeVoiceRepository(
        settings: VoiceSettings(enabled: enabled),
      );
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      await tester.pumpWidget(
        TestApp(
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: long,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: true,
              speaks: true,
            ),
          ),
        ),
      );
      await tester.pump();
      return (speech, voice);
    }

    testWidgets('o texto acompanha a voz e não pisca: entre uma palavra e '
        'outra, segue recortado', (tester) async {
      final (_, voice) = await pumpWithVoice(tester);
      expect(voice.spoken, hasLength(1));
      for (final end in [10, 25, 40]) {
        voice.emit(TtsProgress(end - 5, end));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // A animação até a palavra acabou, e a fala ainda não está inteira.
        expect(find.byType(ClipPath), findsOneWidget);
      }
      voice.emit(const TtsFinished());
      await tester.pumpAndSettle();
      expect(find.byType(ClipPath), findsNothing);
    });

    testWidgets('o botão de velocidade passa para a próxima e recomeça a '
        'fala nela', (tester) async {
      final (speech, voice) = await pumpWithVoice(tester);
      expect(find.text('1×'), findsOneWidget);
      await tester.tap(find.byKey(VoiceKeys.speedButton));
      await tester.pump();
      expect(voice.settings.speed, 1.2);
      expect(find.text('1.2×'), findsOneWidget);
      // Falando, a fala recomeça já na velocidade nova.
      expect(voice.spoken, hasLength(2));
      expect(voice.spoken.last.$2.rate, closeTo(1.2, 1e-9));
      expect(speech.state.isSpeaking(long), isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('um botão de som só: desligado, liga a voz e fala; ligado, '
        'cala e grava a escolha', (tester) async {
      final (speech, voice) = await pumpWithVoice(tester, enabled: false);
      expect(voice.spoken, isEmpty);
      expect(find.byIcon(Icons.volume_off_outlined), findsOneWidget);
      await tester.tap(find.byKey(VoiceKeys.speakButton));
      await tester.pump();
      expect(voice.settings.enabled, isTrue);
      expect(speech.state.isSpeaking(long), isTrue);
      expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
      await tester.tap(find.byKey(VoiceKeys.speakButton));
      await tester.pump();
      expect(voice.settings.enabled, isFalse);
      expect(speech.state.speaking, isNull);
      await tester.pumpAndSettle();
    });
  });

  group('casas e lances tocáveis', () {
    const said = 'O bispo em e4 fecha d5, e depois Tf7.';

    Future<List<String>> pumpLinks(
      WidgetTester tester, {
      bool typed = false,
      SpeechCubit? speech,
    }) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: said,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: typed,
              speaks: speech != null,
              onLink: (link) => tapped.add(link.text),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tapped;
    }

    // O centro da letra [offset] do balão, na tela.
    Offset letter(WidgetTester tester, int offset) {
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(speech_),
          matching: find.byType(RichText),
        ),
      );
      final caret = paragraph.getOffsetForCaret(
        TextPosition(offset: offset),
        Rect.zero,
      );
      return paragraph.localToGlobal(caret + const Offset(4, 10));
    }

    testWidgets('as casas e os lances viram trechos destacados, e tocar '
        'num deles avisa a tela', (tester) async {
      final tapped = await pumpLinks(tester);
      final text = tester.widget<Text>(find.byKey(speech_));
      expect(text.data, isNull);
      expect(text.textSpan!.toPlainText(), said);

      await tester.tapAt(letter(tester, said.indexOf('e4')));
      await tester.tapAt(letter(tester, said.indexOf('Tf7') + 1));
      // Fora de uma casa, nada.
      await tester.tapAt(letter(tester, 2));
      expect(tapped, ['e4', 'Tf7']);
    });

    testWidgets('o dedo que erra a casa por pouco ainda vale nela', (
      tester,
    ) async {
      final tapped = await pumpLinks(tester);
      // Logo depois do fim de "e4", já no espaço seguinte.
      final end = said.indexOf('e4') + 2;
      await tester.tapAt(letter(tester, end) + const Offset(8, 0));
      expect(tapped, ['e4']);
    });

    testWidgets('aparecendo aos poucos: tocar fora de uma casa mostra tudo; '
        'numa casa já à vista, vale na hora', (tester) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: said,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: true,
              onLink: (link) => tapped.add(link.text),
            ),
          ),
        ),
      );
      // Até "e4" à vista, o resto ainda escondido.
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.byType(ClipPath), findsOneWidget);
      await tester.tapAt(letter(tester, said.indexOf('e4')));
      expect(tapped, ['e4']);
      expect(find.byType(ClipPath), findsOneWidget);
      // "Tf7" ainda não apareceu: o toque mostra a fala inteira.
      await tester.tapAt(letter(tester, said.indexOf('Tf7')));
      await tester.pump();
      expect(find.byType(ClipPath), findsNothing);
      expect(tapped, ['e4']);
      await tester.tapAt(letter(tester, said.indexOf('d5')));
      expect(tapped, ['e4', 'd5']);
    });

    testWidgets('com a voz, cada casa aparece quando a voz chega nela', (
      tester,
    ) async {
      final voice = FakeVoiceRepository(
        settings: const VoiceSettings(enabled: true),
      );
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      final tapped = <String>[];
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: said,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              typed: true,
              speaks: true,
              onLink: (_) {},
              onSpoken: (link) => tapped.add(link.text),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(voice.spoken, hasLength(1));
      // A voz passou de "e4" (ainda antes de "d5").
      voice.emit(TtsProgress(said.indexOf('e4') + 3, said.indexOf('e4') + 4));
      await tester.pump();
      expect(tapped, ['e4']);
      voice.emit(TtsProgress(said.indexOf('Tf7') + 1, said.indexOf('Tf7') + 2));
      await tester.pump();
      expect(tapped, ['e4', 'Tf7']);
      await tester.pumpAndSettle();
    });

    testWidgets('RTL: the voice position (source) reveals the whole isolated '
        'move and announces it', (tester) async {
      const arabic = 'النقلة 1.Ke3 تحافظ على الوضع بعد 12 نقلة طويلة جدا.';
      final voice = FakeVoiceRepository(
        settings: const VoiceSettings(enabled: true),
        voices: const [TtsVoice(id: 'ar-a', locale: 'ar')],
      );
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await speech.load();
      final spoken = <String>[];
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('ar'),
          speechCubit: speech,
          child: Scaffold(
            body: TeacherSpeech(
              teacher: FakeCharacterRepository.viktor,
              text: arabic,
              bubbleKey: speech_,
              speechContext: SpeechContext.teaching,
              lessonV2: true,
              typed: true,
              speaks: true,
              onLink: (_) {},
              onSpoken: (link) => spoken.add('${link.start}:${link.text}'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(voice.spoken.single.$1, arabic, reason: 'voice reads the source');
      final end = arabic.indexOf('1.Ke3') + '1.Ke3'.length;
      voice.emit(TtsProgress(end - 1, end));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(spoken, ['${arabic.indexOf('1.Ke3')}:1.Ke3']);
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byKey(speech_),
          matching: find.byType(RichText),
        ),
      );
      final drawn = paragraph.text.toPlainText();
      final at = drawn.indexOf('1.Ke3');
      final clip = tester.widget<ClipPath>(find.byType(ClipPath));
      final path = clip.clipper!.getClip(paragraph.size);
      for (var i = 0; i < 5; i++) {
        final box = paragraph
            .getBoxesForSelection(
              TextSelection(baseOffset: at + i, extentOffset: at + i + 1),
            )
            .single
            .toRect();
        expect(path.contains(box.center), isTrue, reason: 'char $i revealed');
      }
      voice.emit(const TtsFinished());
      await tester.pumpAndSettle();
    });
  });
}
