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

/// The authored explanation of a wrong move, found by the step id.
class _WrongFeedback extends EmptyExerciseFeedbackRepository
    implements ExplanationRepository {
  final asked = <(String, ExplanationState, String?)>[];

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
    asked.add((exerciseId, state, playedUci));
    if (state != ExplanationState.incorrect) return null;
    return ExplanationPayload(
      positionId: exerciseId,
      state: state,
      explanations: [
        ExplanationBlock(
          id: 'played',
          kind: ExplanationKind.playedIncorrect,
          texts: ['$exerciseId: $playedUci does not work.'],
        ),
      ],
    );
  }
}

/// T65 §7: closing the app on a wrong answer (PensarErrado, LanceErrado and
/// Errou) brings back the error and its explanation.
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
              TalkStep(id: 'backrank', fen: mateFen),
              MoveStep(
                id: 'test',
                fen: mateFen,
                line: [
                  MoveTurn(accept: {'a1a8'}),
                ],
                mistakes: {
                  'a1a7': StepMistake(say: 'step.test.a7', review: 'backrank'),
                  'a1a6': StepMistake(),
                },
              ),
              ThinkStep(
                id: 'think',
                fen: mateFen,
                accept: {'a1a8'},
                mistakes: {'a1a2': StepMistake(say: 'step.think.a2')},
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
    'mates.rank.backrank': 'The pawns lock their own king.',
    'mates.rank.test': 'Mate in one.',
    'mates.rank.test.hint': 'Look at the back rank.',
    'mates.rank.test.a7': 'The rook on a7 gives no check.',
    'mates.rank.think': 'Where does the rook go?',
    'mates.rank.think.a2': 'On a2 the rook only defends.',
    'mates.rank.after': 'The rook mates on a8.',
    'coach.wrong': ['Not that one.'],
    'coach.retry': ['Again.'],
  });

  Move move(String uci) => Move.parse(uci)!;

  LessonCubit build(
    FakeSchoolProgressRepository progress, {
    ExerciseFeedbackRepository? feedback,
  }) {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(course: course, texts: texts),
      progress: progress,
      feedback: feedback,
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  /// The app is killed: the checkpoint goes through JSON, as on disk.
  Future<LessonCubit> reopen(
    FakeSchoolProgressRepository progress, {
    ExerciseFeedbackRepository? feedback,
  }) async {
    final stored = await progress.load();
    final json = stored.ongoing!.toJson();
    await progress.save(
      stored.copyWith(ongoing: LessonCheckpoint.fromJson(json)),
    );
    final cubit = build(progress, feedback: feedback);
    await cubit.load('mates.rank', 'en');
    return cubit;
  }

  Future<LessonCubit> openAt(
    FakeSchoolProgressRepository progress,
    int step, {
    ExerciseFeedbackRepository? feedback,
  }) async {
    final cubit = build(progress, feedback: feedback);
    await cubit.load('mates.rank', 'en');
    for (var i = 0; i < step; i++) {
      if (cubit.state.current is MoveStep) await cubit.play(move('a1a8'));
      await cubit.next();
    }
    return cubit;
  }

  test('Errou: the failed phase, speech, review and move come back', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 1);
    await live.play(move('a1a7'));
    expect(live.state.phase, StepPhase.failed);
    final cubit = await reopen(progress);
    final state = cubit.state;
    expect(state.current?.id, 'test');
    expect(state.phase, StepPhase.failed);
    expect(state.layout, LessonLayoutMode.explaining);
    expect(state.speech, 'The rook on a7 gives no check.');
    expect(state.reviewStep, 'backrank');
    expect(state.genericMistake, isFalse);
    expect(state.attemptedSan, '1.Ra7');
    expect(state.mistakes, 1);
    expect(state.fen, mateFen);
    // "Tentar de novo" still works after the restore.
    await cubit.retry();
    expect(cubit.state.phase, StepPhase.active);
    await cubit.play(move('a1a8'));
    expect(cubit.state.phase, StepPhase.done);
  });

  test('Errou without speech: the generic app sentence comes back', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 1);
    await live.play(move('a1a6'));
    final cubit = await reopen(progress);
    expect(cubit.state.phase, StepPhase.failed);
    expect(cubit.state.genericMistake, isTrue);
    expect(cubit.state.reviewStep, isNull);
    expect(cubit.state.attemptedSan, '1.Ra6');
  });

  test('LanceErrado: the hint, the mistake count and the authored '
      'explanation (by step id) come back', () async {
    final progress = FakeSchoolProgressRepository();
    final feedback = _WrongFeedback();
    final live = await openAt(progress, 1, feedback: feedback);
    await live.play(move('a1a5'));
    expect(live.state.phase, StepPhase.active);
    final before = live.state.explanation;
    expect(before?.explanations.single.texts, ['test: a1a5 does not work.']);
    feedback.asked.clear();
    final cubit = await reopen(progress, feedback: feedback);
    await pumpEventQueue();
    final state = cubit.state;
    expect(state.current?.id, 'test');
    expect(state.phase, StepPhase.active);
    expect(state.mistakes, 1);
    expect(state.attemptedSan, '1.Ra5');
    expect(state.explanation?.explanations.single.texts, [
      'test: a1a5 does not work.',
    ]);
    expect(
      feedback.asked,
      contains(('test', ExplanationState.incorrect, 'a1a5')),
    );
  });

  test('second LanceErrado: the arrow of the move comes back', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 1);
    await live.play(move('a1a5'));
    await live.play(move('a1a4'));
    expect(live.state.hint, move('a1a8'));
    final cubit = await reopen(progress);
    expect(cubit.state.mistakes, 2);
    expect(cubit.state.hint, move('a1a8'));
    expect(cubit.state.speech, 'Look at the back rank.');
  });

  test('PensarErrado: the numbered move of the generic sentence comes '
      'back', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 2);
    expect(live.state.current?.id, 'think');
    await live.play(move('a1b1'));
    await pumpEventQueue();
    expect(live.state.current?.id, 'after');
    expect(live.state.thinkMistake, '1.Rb1');
    final cubit = await reopen(progress);
    await pumpEventQueue();
    expect(cubit.state.current?.id, 'after');
    expect(cubit.state.thinkMistake, '1.Rb1');
    expect(cubit.state.attemptedSan, '1.Rb1');
  });

  test('PensarErrado with its own speech: the explanation block comes '
      'back', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 2);
    await live.play(move('a1a2'));
    await pumpEventQueue();
    final cubit = await reopen(progress);
    await pumpEventQueue();
    final explanation = cubit.state.explanation!;
    expect(explanation.state, ExplanationState.incorrect);
    expect(explanation.explanations.first.texts, [
      'On a2 the rook only defends.',
    ]);
    expect(cubit.state.speech, startsWith('On a2 the rook only defends.'));
  });

  test('moving on clears the stored error', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 1);
    await live.play(move('a1a7'));
    await live.retry();
    final saved = (await progress.load()).ongoing!;
    expect(saved.failed, isFalse);
    expect(saved.attempt, isNull);
    final cubit = await reopen(progress);
    expect(cubit.state.phase, StepPhase.active);
    expect(cubit.state.attemptedSan, isNull);
  });

  test('the checkpoint keeps the error fields through JSON', () {
    const checkpoint = LessonCheckpoint(
      lessonId: 'l',
      step: 2,
      attempt: LessonAttempt(
        step: 1,
        id: 'think',
        kind: 'think',
        fen: mateFen,
        turn: 1,
        uci: 'a1b1',
        incorrect: true,
      ),
      failed: true,
      reviewStep: 'intro',
      attemptedSan: '1.Rb1',
      thinkMistake: '1.Rb1',
    );
    final back = LessonCheckpoint.fromJson(checkpoint.toJson());
    expect(back, checkpoint);
    expect(back!.attempt, checkpoint.attempt);
    expect(back.failed, isTrue);
  });

  for (final size in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets('$size: reopening on Errou shows the 2×2 footer and the '
        'explanation', (tester) async {
      final progress = FakeSchoolProgressRepository();
      final live = await openAt(progress, 1);
      await live.play(move('a1a7'));
      final cubit = await reopen(progress);
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      addTearDown(tester.view.reset);
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
      expect(find.byKey(LessonKeys.retryButton), findsOneWidget);
      expect(find.byKey(LessonKeys.reviewPoint), findsOneWidget);
      expect(
        find.textContaining(
          'The rook on a7 gives no check.',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
