import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// T65 painel, lote B (contrato §3, §4): rodapé [Voltar | Ver solução |
/// Continuar], Solução vista persistida, rodapé de 2 linhas, Tentar de novo
/// que recomeça o passo e o tabuleiro jogável depois de Voltar.
void main() {
  const mateFen = '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1';
  const course = Course(
    modules: [
      CourseModule(
        id: 'mates',
        lessons: [
          Lesson(
            id: 'mates.rank',
            steps: [
              MoveStep(
                id: 'first',
                fen: mateFen,
                line: [
                  MoveTurn(accept: {'a1a8'}),
                ],
              ),
              MoveStep(
                id: 'test',
                fen: mateFen,
                line: [
                  MoveTurn(accept: {'a1a8'}),
                ],
              ),
              TalkStep(id: 'after', fen: mateFen),
            ],
          ),
        ],
      ),
    ],
  );
  final texts = LessonTexts.fromJson({
    'mates.rank.title': 'Back rank',
    'mates.rank.first': 'Mate in one.',
    'mates.rank.test': 'Mate in one, again.',
    'mates.rank.after': 'Done.',
    'coach.retry': ['Again.'],
  });

  Move move(String uci) => Move.parse(uci)!;

  LessonCubit build(FakeSchoolProgressRepository progress) {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(course: course, texts: texts),
      progress: progress,
      feedback: _Feedback(),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  /// Aberto no segundo passo de lance, depois do lance errado explicado.
  Future<LessonCubit> failed({FakeSchoolProgressRepository? progress}) async {
    final cubit = build(progress ?? FakeSchoolProgressRepository());
    await cubit.load('mates.rank', 'en');
    await cubit.play(move('a1a8'));
    await cubit.next();
    await cubit.play(move('a1a7'));
    return cubit;
  }

  group('cubit', () {
    test(
      'lance errado explicado: canContinue vale e o erro não muda',
      () async {
        final cubit = await failed();
        expect(cubit.state.phase, StepPhase.failed);
        expect(cubit.state.explanation, isNotNull);
        expect(cubit.state.canContinue, isTrue);
        expect(cubit.state.mistakes, 1);
        expect(cubit.state.solutionSeen, isFalse);
      },
    );

    test('seeSolution marca a solução vista, com a seta no lance certo, e '
        'guarda no checkpoint', () async {
      final progress = FakeSchoolProgressRepository();
      final cubit = await failed(progress: progress);
      await cubit.seeSolution();
      expect(cubit.state.solutionSeen, isTrue);
      expect(cubit.state.phase, StepPhase.failed);
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.solutionMove?.uci, 'a1a8');
      final stored = (await progress.load()).ongoing!;
      expect(stored.solutionSeen, isTrue);
      expect(stored.toJson()['solutionSeen'], isTrue);
      // Só quando verdadeiro.
      await cubit.retry();
      final cleared = (await progress.load()).ongoing!;
      expect(cleared.toJson().containsKey('solutionSeen'), isFalse);
    });

    test('seeSolution fora do erro explicado não faz nada', () async {
      final cubit = build(FakeSchoolProgressRepository());
      await cubit.load('mates.rank', 'en');
      await cubit.seeSolution();
      expect(cubit.state.solutionSeen, isFalse);
    });

    test('Tentar de novo recomeça o passo; o erro contado fica', () async {
      final cubit = await failed();
      await cubit.seeSolution();
      await cubit.retry();
      expect(cubit.state.solutionSeen, isFalse);
      expect(cubit.state.phase, StepPhase.active);
      expect(cubit.state.step, 1);
      expect(cubit.state.fen, mateFen);
      expect(cubit.state.turn, 0);
      expect(cubit.state.explanation, isNull);
      expect(cubit.state.speech, 'Mate in one, again.');
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.interactive, isTrue);
      await cubit.play(move('a1a8'));
      expect(cubit.state.phase, StepPhase.done);
    });

    test('Voltar e Continuar limpam a solução vista', () async {
      var cubit = await failed();
      await cubit.seeSolution();
      await cubit.back();
      expect(cubit.state.solutionSeen, isFalse);
      expect(cubit.state.step, 0);
      expect(cubit.state.interactive, isTrue);
      cubit = await failed();
      await cubit.seeSolution();
      await cubit.next();
      expect(cubit.state.solutionSeen, isFalse);
      expect(cubit.state.step, 2);
    });

    test('fechar à força na Solução vista reabre nela', () async {
      final progress = FakeSchoolProgressRepository();
      final live = await failed(progress: progress);
      await live.seeSolution();
      final stored = await progress.load();
      await progress.save(
        stored.copyWith(
          ongoing: LessonCheckpoint.fromJson(stored.ongoing!.toJson()),
        ),
      );
      final cubit = build(progress);
      await cubit.load('mates.rank', 'en');
      expect(cubit.state.step, 1);
      expect(cubit.state.phase, StepPhase.failed);
      expect(cubit.state.solutionSeen, isTrue);
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.fen, mateFen);
      expect(cubit.state.interactive, isFalse);
    });

    test('checkpoint antigo, sem solutionSeen, abre como sempre', () {
      final old = LessonCheckpoint(lessonId: 'a', step: 1);
      expect(old.solutionSeen, isFalse);
      expect(LessonCheckpoint.fromJson(old.toJson())!.solutionSeen, isFalse);
    });
  });

  group('payload da folha', () {
    final payload = ExplanationPayload(
      positionId: 'p',
      state: ExplanationState.incorrect,
      explanations: [
        ExplanationBlock(
          id: 'played',
          kind: ExplanationKind.playedIncorrect,
          texts: ['1.Ra7? does not mate.'],
        ),
        ExplanationBlock(
          id: 'main',
          kind: ExplanationKind.mainSolution,
          title: 'Anything',
          texts: ['1.Ra8#.'],
        ),
        ExplanationBlock(
          id: 'failed',
          kind: ExplanationKind.failedAlternatives,
          texts: ['Others fail.'],
        ),
      ],
    );

    List<String> ids(ExplanationPayload p) => [
      for (final b in p.explanations) b.id,
    ];

    test('solução vista: lance certo, lance do aluno, falhas', () {
      expect(ids(wrongMoveSheetPayload(payload, correctMoveTitle: 'Correct')), [
        'played',
        'main',
        'failed',
      ]);
      final seen = wrongMoveSheetPayload(
        payload,
        correctMoveTitle: 'Correct',
        solutionSeen: true,
      );
      expect(ids(seen), ['main', 'played', 'failed']);
      expect(seen.explanations.first.title, 'Correct');
    });
  });

  group('tela', () {
    Future<void> show(
      WidgetTester tester,
      LessonCubit cubit,
      Size size, {
      double fontScale = 1,
    }) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = fontScale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final settings = SettingsCubit(
        FakeSettingsRepository(const AppSettings()),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          child: BlocProvider.value(value: cubit, child: const LessonScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> drag(WidgetTester tester, Square from, Square to) async {
      final board = tester.getRect(find.byKey(LessonKeys.board));
      final cell = board.width / 8;
      Offset center(Square s) => Offset(
        board.left + (s.file + .5) * cell,
        board.top + (7 - s.rank + .5) * cell,
      );
      final gesture = await tester.startGesture(center(from));
      await tester.pump();
      final start = center(from);
      final end = center(to);
      for (var i = 1; i <= 5; i++) {
        await gesture.moveTo(Offset.lerp(start, end, i / 5)!);
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();
    }

    for (final size in [const Size(360, 740), const Size(412, 917)]) {
      testWidgets('$size: rodapé do erro 1:1:1, só Continuar cheio', (
        tester,
      ) async {
        final cubit = await tester.runAsync(failed) as LessonCubit;
        await show(tester, cubit, size);
        final back = find.byKey(LessonKeys.backButton);
        final see = find.byKey(LessonKeys.seeSolution);
        final next = find.byKey(LessonKeys.nextButton);
        expect(back, findsOneWidget);
        expect(see, findsOneWidget);
        expect(next, findsOneWidget);
        expect(find.byKey(LessonKeys.reviewPoint), findsNothing);
        expect(find.byKey(LessonKeys.retryButton), findsNothing);
        final rects = [
          for (final f in [back, see, next]) tester.getRect(f),
        ];
        for (final r in rects) {
          expect(r.height, greaterThanOrEqualTo(47));
          expect(r.width, closeTo(rects.first.width, 1));
          expect(r.top, closeTo(rects.first.top, 1));
        }
        expect(rects[1].left - rects[0].right, closeTo(12, 1));
        expect(rects[2].left - rects[1].right, closeTo(12, 1));
        expect(rects[0].left, closeTo(16, 1));
        expect(rects[2].right, closeTo(size.width - 16, 1));
        expect(
          find.descendant(
            of: find.byKey(LessonKeys.footer),
            matching: find.byType(FilledButton),
          ),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Ver solução abre a Solução vista: 2 linhas, 144 dp, '
        'tabuleiro parado', (tester) async {
      final cubit = await tester.runAsync(failed) as LessonCubit;
      await show(tester, cubit, const Size(412, 917));
      await tester.tap(find.byKey(LessonKeys.seeSolution));
      await tester.pumpAndSettle();
      expect(cubit.state.solutionSeen, isTrue);
      final footer = tester.getRect(find.byKey(LessonKeys.solutionFooter));
      expect(footer.height, closeTo(144, 1));
      expect(footer.bottom, closeTo(917, 1));
      final retry = tester.getRect(find.byKey(LessonKeys.retryButton));
      final back = tester.getRect(find.byKey(LessonKeys.backButton));
      final next = tester.getRect(find.byKey(LessonKeys.nextButton));
      expect(retry.width, closeTo(412 - 32, 1));
      expect(retry.height, closeTo(48, 1));
      expect(back.top, closeTo(retry.bottom + 12, 1));
      expect(back.width, closeTo(next.width, 1));
      expect(next.left - back.right, closeTo(12, 1));
      expect(find.byKey(LessonKeys.seeSolution), findsNothing);
      // Um só botão cheio.
      expect(
        find.descendant(
          of: find.byKey(LessonKeys.solutionFooter),
          matching: find.byType(FilledButton),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.replay), findsOneWidget);
      // O tabuleiro está sem toque: arrastar não muda nada.
      final fen = cubit.state.fen;
      await drag(tester, Square.a1, Square.a8);
      expect(cubit.state.fen, fen);
      expect(cubit.state.phase, StepPhase.failed);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tentar de novo: o passo recomeça e o tabuleiro aceita lance', (
      tester,
    ) async {
      final cubit = await tester.runAsync(failed) as LessonCubit;
      await show(tester, cubit, const Size(412, 917));
      await tester.tap(find.byKey(LessonKeys.seeSolution));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LessonKeys.retryButton));
      await tester.pumpAndSettle();
      expect(cubit.state.solutionSeen, isFalse);
      expect(find.byKey(LessonKeys.solutionFooter), findsNothing);
      await drag(tester, Square.a1, Square.a8);
      expect(cubit.state.phase, StepPhase.done);
    });

    testWidgets('Ver solução, Voltar: o passo anterior aceita lance', (
      tester,
    ) async {
      final cubit = await tester.runAsync(failed) as LessonCubit;
      await show(tester, cubit, const Size(412, 917));
      await tester.tap(find.byKey(LessonKeys.seeSolution));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(LessonKeys.backButton));
      await tester.pumpAndSettle();
      expect(cubit.state.step, 0);
      await drag(tester, Square.a1, Square.a8);
      expect(cubit.state.phase, StepPhase.done);
    });

    testWidgets('Continuar no erro avança para o próximo passo', (
      tester,
    ) async {
      final cubit = await tester.runAsync(failed) as LessonCubit;
      await show(tester, cubit, const Size(412, 917));
      await tester.tap(find.byKey(LessonKeys.nextButton));
      await tester.pumpAndSettle();
      expect(cubit.state.step, 2);
    });

    testWidgets('fonte 2,0: rodapé de 2 linhas sem estouro', (tester) async {
      final cubit = await tester.runAsync(failed) as LessonCubit;
      await show(tester, cubit, const Size(360, 740), fontScale: 2);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(LessonKeys.seeSolution));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(LessonKeys.solutionFooter), findsOneWidget);
    });

    testWidgets('360x640: a folha abre expandida, com X e rodapé visíveis', (
      tester,
    ) async {
      final cubit = await tester.runAsync(failed) as LessonCubit;
      await show(tester, cubit, const Size(360, 640));
      await tester.tap(find.byKey(LessonKeys.seeSolution));
      await tester.pumpAndSettle();
      final close = tester.getRect(find.byKey(LessonKeys.closeSheet));
      expect(close.top, greaterThanOrEqualTo(0));
      expect(close.height, greaterThanOrEqualTo(48));
      final footer = tester.getRect(find.byKey(LessonKeys.solutionFooter));
      expect(footer.bottom, closeTo(640, 1));
      expect(footer.height, closeTo(144, 1));
      final board = tester.getRect(find.byKey(LessonKeys.board));
      final sheet = tester.getRect(find.byKey(LessonKeys.viktorSheet));
      // Modal sobre o tabuleiro: a folha começa acima da borda dele.
      final top = tester.getTopLeft(find.byKey(LessonKeys.scroll)).dy;
      expect(top, lessThan(board.bottom));
      expect(sheet.bottom, lessThanOrEqualTo(640));
      expect(tester.takeException(), isNull);
    });
  });
}

/// Devolve, para o lance errado a1a7, a explicação do erro com o lance certo.
class _Feedback extends EmptyExerciseFeedbackRepository
    implements ExplanationRepository {
  @override
  Future<ExplanationPayload?> findPayload({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String language,
    required ExplanationState state,
    String? playedUci,
  }) async {
    if (kind != 'move' ||
        exerciseId != 'test' ||
        state != ExplanationState.incorrect) {
      return null;
    }
    ExplanationVariation variation(String id, String uci, bool accepted) =>
        ExplanationVariation(
          id: id,
          label: uci,
          outcome: accepted
              ? VariationOutcome.accepted
              : VariationOutcome.doesNotMeetGoal,
          texts: const ['Text'],
          originFen: fen,
          movesUci: [uci],
          movesSan: [uci],
          validated: true,
        );
    return ExplanationPayload(
      positionId: 'move/$exerciseId.$turn',
      reviewStepId: 'first',
      state: ExplanationState.incorrect,
      explanations: [
        ExplanationBlock(
          id: 'played',
          kind: ExplanationKind.playedIncorrect,
          texts: const ['1.Ra7? does not mate.'],
          variations: [variation('bad', 'a1a7', false)],
        ),
        ExplanationBlock(
          id: 'main',
          kind: ExplanationKind.mainSolution,
          texts: const ['1.Ra8# mates.'],
          variations: [variation('good', 'a1a8', true)],
        ),
      ],
    );
  }
}
