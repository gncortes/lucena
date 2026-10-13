import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/voice.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';

import 'package:lucena/domain/use_cases/engine_fallback.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';
import 'package:lucena/ui/core/keys/lesson_v2_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/typing_dots.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<LessonCubit> build({
    required FakeNow now,
    int score = 900,
    bool throws = false,
    Duration typing = Duration.zero,
    bool branch = false,
  }) async {
    final lesson = LessonCubit(
      lessons: FakeLessonRepository(
        course: Course(
          modules: [
            CourseModule(
              id: 'pieces',
              lessons: [
                Lesson(
                  id: 'pieces.demo',
                  steps: [
                    DemoStep(
                      id: 'demo',
                      lines: [
                        if (branch)
                          CitedLine(
                            uci: ['c1c4', 'a2a1', 'c4c5'],
                            branches: [
                              CitedBranch(
                                id: 'rook',
                                at: 0,
                                uci: ['c1c2', 'a2a1'],
                              ),
                            ],
                          ),
                      ],
                      fen: FakeEndgameLessonRepository.lucenaFen,
                      line: [
                        DemoMove(uci: 'c1c4'),
                        DemoMove(uci: 'a2a1'),
                        DemoMove(uci: 'c4c5'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        texts: LessonTexts.fromJson({
          'pieces.demo.title': 'Demonstration',
          'pieces.demo.demo': 'Watch.',
          'pieces.demo.demo.m1': 'The rook moves.',
          'pieces.demo.demo.alt.rook': 'This branch also works.',
        }),
      ),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      now: now,
      typingDelay: typing,
      engine: EngineFallback(
        evaluate: (position, pov) async {
          if (throws) throw StateError('motor');
          return Evaluation(centipawns: score);
        },
        bestMove: (position) async => position.legalMoves.entries
            .map((e) => NormalMove(from: e.key, to: e.value.squares.first))
            .first,
      ),
    );
    addTearDown(lesson.close);
    await lesson.load('pieces.demo', 'en');
    return lesson;
  }

  test('pausada, a demo segue pausada no ⏭ (crit. 19)', () async {
    final lesson = await build(now: FakeNow(DateTime.utc(2026, 10, 13)));
    lesson.demoTogglePause();
    await lesson.demoForward();
    expect(lesson.state.demoMove, 1);
    expect(lesson.state.demoPlaying, isFalse);
  });

  test('lance do roteiro = ⏭; lance do adversário é ignorado', () async {
    final lesson = await build(now: FakeNow(DateTime.utc(2026, 10, 13)));
    await lesson.play(Move.parse('c1c4')!);
    expect(lesson.state.demoMove, 1);
    expect(lesson.state.offScript, isFalse);
    expect(lesson.state.demoPlaying, isFalse);
    final fen = lesson.state.fen;
    await lesson.play(Move.parse('a2a3')!);
    expect(lesson.state.fen, fen);
  });

  test(
    'lance fora do roteiro pausa, o motor responde e o ⏮ desfaz o par',
    () async {
      final lesson = await build(now: FakeNow(DateTime.utc(2026, 10, 13)));
      final start = lesson.state.fen;
      await lesson.play(Move.parse('c1c2')!);
      expect(lesson.state.demoPlaying, isFalse);
      expect(lesson.state.offScript, isTrue);
      expect(lesson.state.demoOff.length, 2);
      expect(lesson.state.note, LessonNote.alsoWins);
      await lesson.demoBack();
      expect(lesson.state.offScript, isFalse);
      expect(lesson.state.fen, start);
    },
  );

  test('não mantém o resultado: refutação; erro do motor desfaz', () async {
    final lost = await build(
      now: FakeNow(DateTime.utc(2026, 10, 13)),
      score: 0,
    );
    await lost.play(Move.parse('c1c2')!);
    expect(lost.state.note, LessonNote.engineReply);
    final failed = await build(
      now: FakeNow(DateTime.utc(2026, 10, 13)),
      throws: true,
    );
    final start = failed.state.fen;
    await failed.play(Move.parse('c1c2')!);
    expect(failed.state.fen, start);
    expect(failed.state.engineErrors, 1);
    expect(failed.state.offScript, isFalse);
  });

  test('lance de um ramo dos dados segue o ramo, sem motor', () async {
    final lesson = await build(
      now: FakeNow(DateTime.utc(2026, 10, 13)),
      branch: true,
      throws: true,
    );
    await lesson.play(Move.parse('c1c2')!);
    expect(lesson.state.offScript, isTrue);
    expect(lesson.state.demoOff, ['c1c2', 'a2a1']);
    expect(lesson.state.speech, 'This branch also works.');
    expect(lesson.state.engineErrors, 0);
    expect(lesson.state.typing, isFalse);
    expect(lesson.state.demoPlaying, isFalse);
    // Lance sem ramo continua indo ao motor.
    final other = await build(
      now: FakeNow(DateTime.utc(2026, 10, 13)),
      branch: true,
    );
    await other.play(Move.parse('c1c3')!);
    expect(other.state.note, LessonNote.alsoWins);
  });

  test('⏭ fora do roteiro volta ao roteiro e anda um lance, pausado', () async {
    final lesson = await build(now: FakeNow(DateTime.utc(2026, 10, 13)));
    await lesson.play(Move.parse('c1c2')!);
    expect(lesson.state.offScript, isTrue);
    await lesson.demoForward();
    expect(lesson.state.offScript, isFalse);
    expect(lesson.state.demoMove, 1);
    expect(lesson.state.demoPlaying, isFalse);
  });

  testWidgets('erro do motor: a snackbar fica acima do rodapé da demo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final lesson = await build(
      now: FakeNow(DateTime.utc(2026, 10, 13)),
      throws: true,
      typing: const Duration(milliseconds: 300),
    );
    final speech = SpeechCubit(
      FakeVoiceRepository(settings: const VoiceSettings(enabled: false)),
    );
    addTearDown(speech.close);
    await speech.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings(sound: false)),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        speechCubit: speech,
        child: BlocProvider.value(value: lesson, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    final played = lesson.play(Move.parse('c1c2')!);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await played;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final snack = find.byKey(LessonKeys.engineErrorSnack);
    expect(snack, findsOneWidget);
    expect(
      tester
          .getRect(find.descendant(of: snack, matching: find.byType(Text)))
          .bottom,
      lessThanOrEqualTo(tester.getRect(find.byKey(LessonKeys.demoPause)).top),
    );
  });

  const sizes = [Size(360, 740), Size(412, 917)];
  for (final size in sizes) {
    testWidgets(
      '${size.width.toInt()}x${size.height.toInt()}: "Voltar à demonstração" aparece fora do roteiro e leva ao lance',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final now = FakeNow(DateTime.utc(2026, 10, 13));
        final lesson = await build(
          now: now,
          typing: const Duration(milliseconds: 300),
        );
        final speech = SpeechCubit(
          FakeVoiceRepository(settings: const VoiceSettings(enabled: false)),
        );
        addTearDown(speech.close);
        await speech.load();
        final settings = SettingsCubit(
          FakeSettingsRepository(const AppSettings(sound: false)),
          languages: AppLanguage.selectable,
        );
        addTearDown(settings.close);
        await settings.load();
        await tester.pumpWidget(
          TestApp(
            settingsCubit: settings,
            speechCubit: speech,
            child: BlocProvider.value(
              value: lesson,
              child: const LessonScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        addTearDown(() => tester.pumpWidget(const SizedBox()));
        expect(find.byKey(LessonKeys.demoBackToScript), findsNothing);
        expect(find.textContaining('Paus'), findsNothing);
        // Pausada: 10 s depois nada andou.
        lesson.demoTogglePause();
        for (var i = 0; i < 40; i++) {
          now.advance(const Duration(milliseconds: 250));
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(lesson.state.demoMove, 0);
        final played = lesson.play(Move.parse('c1c2')!);
        await tester.pump();
        // A máquina pensa: três pontos na folha (pg. 2.3).
        await tester.pump(const Duration(milliseconds: 20));
        expect(find.byKey(LessonKeys.sheetTyping), findsOneWidget);
        // Os pontinhos centralizados no lugar do texto, que some.
        expect(
          tester.getCenter(find.byType(TypingDots)).dx,
          closeTo(size.width / 2, 1),
        );
        expect(find.text('Watch.'), findsNothing);
        await tester.pump(const Duration(milliseconds: 400));
        await played;
        await tester.pumpAndSettle();
        expect(find.byKey(LessonKeys.sheetTyping), findsNothing);
        final button = find.byKey(LessonKeys.demoBackToScript);
        expect(button, findsOneWidget);
        expect(tester.getSize(button), Size(size.width - 32, 48));
        expect(find.text('Back to the demonstration'), findsOneWidget);
        expect(find.textContaining('Well done'), findsOneWidget);
        for (final key in [
          LessonKeys.backButton,
          LessonKeys.demoReplay,
          LessonKeys.demoBack,
          LessonKeys.demoPause,
          LessonKeys.demoForward,
        ]) {
          expect(
            tester.getSize(find.byKey(key)).shortestSide,
            greaterThanOrEqualTo(48),
          );
        }
        // Fora do roteiro o ⏭ segue ativo (pg. 2.5).
        expect(
          tester
              .widget<IconButton>(find.byKey(LessonKeys.demoForward))
              .onPressed,
          isNotNull,
        );
        expect(find.byKey(LessonV2Keys.freeBoardInvite), findsNothing);
        expect(find.byKey(LessonV2Keys.openFreeBoard), findsNothing);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(button, findsNothing);
        expect(lesson.state.demoMove, 0);
        expect(lesson.state.demoPlaying, isFalse);
      },
    );
  }

  testWidgets('pausado: ⏭ anda um lance e o play segue como play; retomar '
      'recomeça a contagem', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = FakeNow(DateTime.utc(2026, 10, 13));
    final lesson = await build(now: now);
    final speech = SpeechCubit(
      FakeVoiceRepository(settings: const VoiceSettings(enabled: false)),
    );
    addTearDown(speech.close);
    await speech.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings(sound: false)),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        speechCubit: speech,
        child: BlocProvider.value(value: lesson, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    Future<void> tick(int n) async {
      for (var i = 0; i < n; i++) {
        now.advance(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    IconData? pauseIcon() => tester
        .widget<Icon>(
          find.descendant(
            of: find.byKey(LessonKeys.demoPause),
            matching: find.byType(Icon),
          ),
        )
        .icon;
    expect(pauseIcon(), Icons.pause_rounded);
    await tick(4);
    await tester.tap(find.byKey(LessonKeys.demoPause));
    await tester.pump();
    expect(pauseIcon(), Icons.play_arrow_rounded);
    await tester.tap(find.byKey(LessonKeys.demoForward));
    await tester.pump();
    expect(lesson.state.demoMove, 1);
    expect(lesson.state.demoPlaying, isFalse);
    expect(pauseIcon(), Icons.play_arrow_rounded);
    await tick(40);
    expect(lesson.state.demoMove, 1);
    // Retomar: a contagem recomeça (não sai lance logo).
    await tester.tap(find.byKey(LessonKeys.demoPause));
    await tick(4);
    expect(lesson.state.demoMove, 1);
    await tick(32);
    expect(lesson.state.demoMove, greaterThan(1));
  });
}
