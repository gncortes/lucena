import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

/// Decisão de 2026-10-13: fechar o app de verdade reabre no início da lição,
/// qualquer que fosse o erro na tela; o checkpoint ainda guarda os campos.
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

  test('closing on a wrong answer reopens at step 0 with no error', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 1);
    await live.play(move('a1a7'));
    expect(live.state.attemptedSan, isNotNull);
    final cubit = await reopen(progress);
    expect(cubit.state.step, 0);
    expect(cubit.state.attemptedSan, isNull);
    expect((await progress.load()).ongoing!.step, 0);
  });

  test('an old checkpoint with a saved step reopens at step 0', () async {
    final progress = FakeSchoolProgressRepository();
    await progress.save(
      (await progress.load()).copyWith(
        ongoing: const LessonCheckpoint(lessonId: 'mates.rank', step: 2),
      ),
    );
    final cubit = build(progress);
    await cubit.load('mates.rank', 'en');
    expect(cubit.state.step, 0);
    expect(cubit.state.current?.id, 'backrank');
  });

  test('moving on clears the stored error', () async {
    final progress = FakeSchoolProgressRepository();
    final live = await openAt(progress, 1);
    await live.play(move('a1a7'));
    await live.retry();
    final cubit = await reopen(progress);
    expect(cubit.state.phase, StepPhase.active);
    expect(cubit.state.attemptedSan, isNull);
  });

  test('an old checkpoint with error fields still reads', () {
    final back = LessonCheckpoint.fromJson({
      'lesson': 'l',
      'step': 2,
      'part': 'p',
      'attempt': {'step': 1, 'id': 'think', 'kind': 'think'},
      'failed': true,
      'reviewStep': 'intro',
      'attemptedSan': '1.Rb1',
      'thinkMistake': '1.Rb1',
      'solutionSeen': true,
      'reviewReturn': {'lesson': 'l', 'step': 1},
    });
    expect(
      back,
      const LessonCheckpoint(lessonId: 'l', step: 2, part: 'p', open: false),
    );
    expect(back!.toJson().keys, isNot(contains('failed')));
  });
}
