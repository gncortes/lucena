import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_progress_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';

class _FailingPreferences extends PreferencesService {
  bool failNextWrite = false;
  @override
  Future<void> setString(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('disk');
    }
    await super.setString(key, value);
  }
}

void main() {
  const id = 'pilares.c2';
  final original = FakeEndgameLessonRepository.sample.lessons.first;
  // Different weights prove correct-answer counts never equal a point sum.
  final lesson = EndgameLesson(
    id: id,
    module: 'pilares',
    lesson: const Lesson(id: id, steps: []),
    exercises: [
      for (var i = 0; i < 12; i++)
        Exercise(
          id: 'e$i',
          stars: i % 3 + 1,
          fen: FakeEndgameLessonRepository.lucenaFen,
          goal: original.exercises.first.goal,
          line: original.exercises.first.line,
        ),
    ],
    passScore: 9,
    keyPositions: const [],
  );
  final lessons = FakeEndgameLessonRepository(
    trail: EndgameTrail(
      modules: [
        EndgameModule(id: 'pilares', lessons: [lesson]),
      ],
    ),
  );
  final now = FakeNow(DateTime.utc(2026, 10, 30));
  late LocalEndgameProgressRepository progress;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    progress = LocalEndgameProgressRepository(PreferencesService());
  });

  Future<ExerciseCubit> open(int index) async {
    final cubit = ExerciseCubit(
      lessons: lessons,
      progress: progress,
      characters: FakeCharacterRepository(),
      now: now,
    );
    await cubit.load(id, 'e$index', 'pt', restartPosition: true);
    return cubit;
  }

  Future<void> answer(int index, bool correct) async {
    final cubit = await open(index);
    await cubit.submitTestMove(Move.parse(correct ? 'c1c4' : 'c1c2')!);
    expect(cubit.state.phase, ExercisePhase.done);
    expect(cubit.state.earned, correct ? lesson.exercises[index].stars : 0);
    await cubit.close();
  }

  Future<EndgameLessonCubit> chapter() async {
    final cubit = EndgameLessonCubit(
      lessons: lessons,
      progress: progress,
      journey: FakeJourneyRepository(),
      characters: FakeCharacterRepository(),
    );
    await cubit.load(id, 'pt');
    return cubit;
  }

  Future<CourseGuideCubit> guide() async {
    final repository = FakeTrainingRepository(
      content: {
        TrainingCourse.pilares: TrainingResources(
          lessons: const [
            TrainingLesson(
              id: id,
              kind: TrainingLessonKind.test,
              title: 'Teste',
            ),
          ],
        ),
      },
    );
    addTearDown(repository.dispose);
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.pilares,
      now: now,
      testLessons: lessons,
      testProgress: progress,
    );
    await cubit.load();
    return cubit;
  }

  for (final correct in [12, 11, 10, 9, 8, 7]) {
    test(
      '$correct of 12: persisted correctness and medal independent of weights',
      () async {
        for (var i = 0; i < 12; i++) {
          await answer(i, i < correct);
        }
        final reopened = LocalEndgameProgressRepository(PreferencesService());
        final saved = (await reopened.load()).of(id);
        expect(saved.lastTestAnswers, hasLength(12));
        expect(
          saved.lastTestAnswers!.values.where((value) => value),
          hasLength(correct),
        );
        final current = await chapter();
        expect(current.state.score, correct);
        expect(current.state.maxScore, 12);
        expect(
          current.state.grade.index,
          ChapterTestScores.gradeIndex(correct, 12),
        );
        await current.close();
        final course = await guide();
        expect(course.state.testScores[id], (100 * correct / 12).round());
        expect(course.state.testProgress[id]?.score, correct);
        expect(course.state.testProgress[id]?.maxScore, 12);
        await course.close();
      },
    );
  }

  test('force-close resumes unanswered question; partial retake keeps last completed grade; lower final replaces it', () async {
    await answer(0, true);
    await answer(1, false);
    var record = (await progress.load()).of(id);
    expect(record.stars, hasLength(2));
    expect(record.lastTestAnswers, isNull);
    expect(record.completedTestOf(lesson), isNull);
    var current = await chapter();
    expect(current.state.nextExercise?.id, 'e2');
    await current.close();
    final reopened = await open(2);
    expect(reopened.state.number, 3);
    expect(reopened.state.fen, lesson.exercises[2].fen);
    await reopened.close();
    for (var i = 2; i < 12; i++) {
      await answer(i, true);
    }
    current = await chapter();
    expect(current.state.score, 11);
    await current.redoExercises();
    expect(current.state.nextExercise?.id, 'e0');
    expect(current.state.score, 11);
    await current.close();
    await answer(0, false);
    record = (await progress.load()).of(id);
    expect(record.stars, {'e0': 0});
    expect(
      record.lastTestAnswers!.values.where((value) => value),
      hasLength(11),
    );
    var course = await guide();
    expect(course.state.testScores[id], 92);
    expect(course.state.testProgress[id]?.solved, 12);
    await course.close();
    for (var i = 1; i < 12; i++) {
      await answer(i, i <= 7);
    }
    current = await chapter();
    expect(current.state.score, 7);
    expect(current.state.grade, ExerciseGrade.below);
    await current.close();
    course = await guide();
    expect(course.state.testScores[id], 58);
    await course.close();
  });

  test('thresholds are proportional for shorter banks', () {
    expect(ChapterTestScores.passed(5), 4);
    expect(ChapterTestScores.gradeIndex(2, 5), 0);
    expect(ChapterTestScores.gradeIndex(0, 0), 0);
    expect(ChapterTestScores.gradeIndex(38, 46), ExerciseGrade.passed.index);
    expect(ChapterTestScores.gradeIndex(39, 46), ExerciseGrade.good.index);
  });

  test(
    'failed save keeps the question active; retry records exactly one answer',
    () async {
      final preferences = _FailingPreferences();
      final repository = LocalEndgameProgressRepository(preferences);
      final cubit = ExerciseCubit(
        lessons: lessons,
        progress: repository,
        characters: FakeCharacterRepository(),
        now: now,
      );
      await cubit.load(id, 'e0', 'pt');
      preferences.failNextWrite = true;
      await expectLater(
        cubit.submitTestMove(Move.parse('c1c4')!),
        throwsStateError,
      );
      expect(cubit.state.phase, ExercisePhase.active);
      expect(cubit.state.interactive, false);
      expect(cubit.state.testAnswerPending, true);
      expect((await repository.load()).of(id).stars, isEmpty);
      await cubit.submitTestMove(Move.parse('c1c4')!);
      expect((await repository.load()).of(id).stars, {'e0': 1});
      expect(cubit.state.testAnswerPending, false);
      await cubit.close();
    },
  );

  for (final firstCorrect in [false, true]) {
    test(
      'failed save cannot replace the first answer: correct=$firstCorrect',
      () async {
        final preferences = _FailingPreferences();
        final repository = LocalEndgameProgressRepository(preferences);
        final cubit = ExerciseCubit(
          lessons: lessons,
          progress: repository,
          characters: FakeCharacterRepository(),
          now: now,
        );
        addTearDown(cubit.close);
        await cubit.load(id, 'e0', 'pt');
        preferences.failNextWrite = true;
        await expectLater(
          cubit.submitTestMove(Move.parse(firstCorrect ? 'c1c4' : 'c1c2')!),
          throwsStateError,
        );
        expect(cubit.state.interactive, false);
        await cubit.submitTestMove(Move.parse(firstCorrect ? 'c1c2' : 'c1c4')!);
        expect((await repository.load()).of(id).stars, {
          'e0': firstCorrect ? 1 : 0,
        });
        expect(cubit.state.phase, ExercisePhase.done);
        expect(cubit.state.testAnswerPending, false);
      },
    );
  }

  test('concurrent input cannot overwrite the first answer', () async {
    final cubit = await open(0);
    await Future.wait([
      cubit.submitTestMove(Move.parse('c1c4')!),
      cubit.submitTestMove(Move.parse('c1c2')!),
    ]);
    expect((await progress.load()).of(id).stars, {'e0': 1});
    await cubit.close();
  });
}
