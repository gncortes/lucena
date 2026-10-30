import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_exercise.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/training_analytics.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';

void main() {
  final exercise = TrainingExercise(
    id: 'e',
    stars: 1,
    fen: GameRules.initial.fen,
    solution: ['e2e4', 'e7e5', 'g1f3'],
  );
  final goal = TrainingGoal(
    kind: GoalKind.exercise,
    ref: 'lesson',
    itemId: 'e',
    stars: 1,
  );
  final now = FakeNow(DateTime(2026, 10, 29, 12));
  late FakeTrainingRepository repository;
  late TrainingExerciseCubit cubit;

  TrainingState saved({ThemeCycle? cycle, TrainingGoal? selected}) =>
      TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'test',
        day: DayGoals(
          date: '2026-10-29',
          studyDay: true,
          goals: [selected ?? goal],
        ),
        cycles: {
          'lesson':
              cycle ?? ThemeCycle(lessonId: 'lesson', startedOn: '2026-10-20'),
        },
      );
  TrainingExerciseCubit create() => TrainingExerciseCubit(
    repository: repository,
    config: TrainingCourseConfig.pilares,
    now: now,
    goalKey: goal.key,
  );
  setUp(() async {
    now.value = DateTime(2026, 10, 29, 12);
    repository = FakeTrainingRepository(
      states: {TrainingCourse.pilares: saved()},
      content: {
        TrainingCourse.pilares: TrainingResources(
          banks: {
            'lesson': [exercise],
          },
        ),
      },
    );
    cubit = create();
    await cubit.load();
  });
  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('plays opponent reply then waits for remaining student move', () async {
    await cubit.play('e2e4');
    expect(cubit.state.cursor, 2);
    expect(cubit.state.lastMove, 'e7e5');
    expect(cubit.state.phase, TrainingExercisePhase.playing);
    expect(repository.writes, 0);
    await cubit.play('g1f3');
    expect(cubit.state.phase, TrainingExercisePhase.result);
    expect(cubit.state.correct, true);
    final stored = await repository.load(TrainingCourse.pilares);
    expect(stored.day!.allDone, true);
    expect(stored.cycles['lesson']!.days.single.earned, true);
    await cubit.play('f1c4');
    expect(repository.writes, 1);
    expect(cubit.next(), true);
  });

  test('wrong move ends one attempt and shows correct move', () async {
    await cubit.play('d2d4');
    expect(cubit.state.correct, false);
    expect(cubit.state.lastMove, 'e2e4');
    expect(cubit.state.phase, TrainingExercisePhase.result);
    expect(cubit.state.cycle!.hadError, true);
    expect(cubit.state.cycle!.days.single.correct, false);
    expect(cubit.state.errorFeedback, isNull);
  });

  test(
    'real feedback undoes error and practice never rewrites the score',
    () async {
      const feedback = 'Uma explicação aprovada. Que recurso existe?';
      repository.content[TrainingCourse.pilares] = TrainingResources(
        banks: {
          'lesson': [exercise],
        },
        errorFeedback: {
          'lesson': {'e.1.d2d4': feedback},
        },
      );
      await cubit.load();
      final initial = await repository.load(TrainingCourse.pilares);
      await cubit.play('d2d4');
      expect(cubit.state.errorFeedback, feedback);
      expect(cubit.state.fen, exercise.fen);
      expect(cubit.state.lastMove, exercise.lastMove);
      final stored = await repository.load(TrainingCourse.pilares);
      expect(
        trainingAnalyticsDiff(
          initial,
          stored,
          now: now(),
        ).where((event) => event.name == 'treino_meta_fim'),
        hasLength(1),
      );
      expect(stored.day!.goals.single.exerciseError!.wrongMove, 'd2d4');
      expect(stored.day!.goals.single.exerciseError!.feedbackShown, true);
      final writes = repository.writes;
      cubit.retryPractice();
      expect(cubit.state.phase, TrainingExercisePhase.playing);
      await cubit.hint();
      expect(cubit.state.hint, true);
      expect(cubit.state.phase, TrainingExercisePhase.playing);
      expect(repository.writes, writes);
      await cubit.play('e2e4');
      await cubit.play('g1f3');
      expect(cubit.state.phase, TrainingExercisePhase.result);
      expect(cubit.state.practiceCorrect, true);
      expect(cubit.state.correct, false);
      expect(cubit.next(), true);
      expect(repository.writes, writes);
      expect(
        (await repository.load(TrainingCourse.pilares)).toJson(),
        stored.toJson(),
      );
      expect(
        trainingAnalyticsDiff(
          stored,
          await repository.load(TrainingCourse.pilares),
          now: now(),
        ),
        isEmpty,
      );
    },
  );

  test(
    'second student turn feedback survives serialization and restart',
    () async {
      const feedback = 'Segunda posição. Que recurso existe?';
      repository.content[TrainingCourse.pilares] = TrainingResources(
        banks: {
          'lesson': [exercise],
        },
        errorFeedback: {
          'lesson': {
            'e.1.f1c4': 'Texto da posição errada',
            'e.2.f1c4': feedback,
          },
        },
      );
      await cubit.load();
      await cubit.play('e2e4');
      final before = cubit.state.fen;
      await cubit.play('f1c4');
      expect(cubit.state.errorFeedback, feedback);
      expect(cubit.state.fen, before);
      final reopened = create();
      addTearDown(reopened.close);
      await reopened.load();
      expect(reopened.state.errorFeedback, feedback);
      expect(reopened.state.fen, before);
      reopened.retryPractice();
      expect(reopened.state.cursor, 2);
      expect(reopened.state.lastMove, 'e7e5');
      final writes = repository.writes;
      await reopened.play('g1f3');
      expect(repository.writes, writes);
      expect(reopened.state.correct, false);
    },
  );

  test(
    'feedback save failure blocks practice until result is durable',
    () async {
      repository.content[TrainingCourse.pilares] = TrainingResources(
        banks: {
          'lesson': [exercise],
        },
        errorFeedback: {
          'lesson': {'e.1.d2d4': 'Texto?'},
        },
      );
      await cubit.load();
      repository.writeError = StateError('disk');
      await cubit.play('d2d4');
      cubit.retryPractice();
      expect(cubit.state.phase, TrainingExercisePhase.saving);
      expect(repository.writes, 0);
      repository.writeError = null;
      await cubit.save();
      expect(repository.writes, 1);
      expect(cubit.state.errorFeedback, 'Texto?');
      cubit.retryPractice();
      await cubit.play('d2d4');
      expect(repository.writes, 1);
      expect(cubit.state.errorFeedback, 'Texto?');
    },
  );

  test(
    'hint resolves as correct UI but scores error and lowers level',
    () async {
      final hard = TrainingExercise(
        id: 'e',
        stars: 2,
        fen: exercise.fen,
        solution: exercise.solution,
      );
      repository.content[TrainingCourse.pilares] = TrainingResources(
        banks: {
          'lesson': [hard],
        },
      );
      await repository.update(
        TrainingCourse.pilares,
        (_) => saved(
          cycle: ThemeCycle(
            lessonId: 'lesson',
            startedOn: '2026-10-20',
            level: 2,
          ),
        ),
      );
      await cubit.load();
      await cubit.hint();
      await cubit.play('e2e4');
      await cubit.play('g1f3');
      expect(cubit.state.correct, true);
      expect(cubit.state.cycle!.days.single.hint, true);
      expect(cubit.state.cycle!.days.single.earned, false);
      expect(cubit.state.cycle!.level, 1);
      expect(cubit.state.cycle!.score, 0);
    },
  );

  test(
    'interruption restarts same frozen exercise; completed never scores twice',
    () async {
      await cubit.play('e2e4');
      final reopened = create();
      await reopened.load();
      expect(reopened.state.fen, exercise.fen);
      expect(reopened.state.cursor, 0);
      expect(reopened.state.exercise!.id, 'e');
      await reopened.play('d2d4');
      await reopened.close();
      await cubit.play('g1f3');
      expect(repository.writes, 1);
      final stored = await repository.load(TrainingCourse.pilares);
      expect(stored.cycles['lesson']!.days.length, 1);
      expect(cubit.state.correct, false);
      expect(cubit.state.hint, stored.cycles['lesson']!.days.single.hint);
    },
  );

  test('save failure keeps result retryable and blocks navigation', () async {
    repository.writeError = StateError('disk');
    await cubit.play('d2d4');
    expect(cubit.state.phase, TrainingExercisePhase.saving);
    expect(cubit.state.error, true);
    expect(cubit.next(), false);
    repository.writeError = null;
    await cubit.save();
    expect(cubit.state.phase, TrainingExercisePhase.result);
    expect(repository.writes, 1);
  });

  test(
    'hint persists before reveal and remains after restarting the exercise',
    () async {
      final otherGoal = TrainingGoal(
        kind: GoalKind.exercise,
        ref: 'other',
        itemId: 'other',
      );
      await repository.update(
        TrainingCourse.pilares,
        (current) => current.copyWith(
          day: current.day!.copyWith(goals: [goal, otherGoal]),
        ),
      );
      final gate = Completer<void>();
      repository.beforeSave = gate.future;
      final hinting = cubit.hint();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.hint, false);
      expect(cubit.state.phase, TrainingExercisePhase.hintSaving);
      await cubit.play('e2e4');
      expect(cubit.state.cursor, 0);
      gate.complete();
      await hinting;
      expect(cubit.state.hint, true);
      final stored = await repository.load(TrainingCourse.pilares);
      expect(stored.day!.goals.first.hintUsed, true);
      expect(stored.day!.goals.last.hintUsed, false);
      final reopened = create();
      await reopened.load();
      expect(reopened.state.hint, true);
      expect(reopened.state.cursor, 0);
      await reopened.close();
    },
  );

  test('hint write failure reveals nothing and allows retry', () async {
    repository.writeError = StateError('disk');
    await cubit.hint();
    expect(cubit.state.phase, TrainingExercisePhase.playing);
    expect(cubit.state.hint, false);
    expect(cubit.state.error, true);
    expect(repository.writes, 0);
    repository.writeError = null;
    await cubit.hint();
    expect(cubit.state.hint, true);
    expect(repository.writes, 1);
  });

  test('goal hint JSON is backward compatible and complete preserves hint', () {
    final legacy = goal.toJson()..remove('hintUsed');
    expect(TrainingGoal.fromJson(legacy).hintUsed, false);
    final hinted = goal.withHint();
    expect(TrainingGoal.fromJson(hinted.toJson()).hintUsed, true);
    expect(hinted.complete().hintUsed, true);
    expect(hinted.complete().done, true);
    expect(goal.hintUsed, false);
    expect(
      TrainingGoal(kind: goal.kind, ref: goal.ref, itemId: 'new').hintUsed,
      false,
    );
  });

  test(
    'hint carries across missed study day only for the same pending item',
    () async {
      repository.content[TrainingCourse.pilares] = TrainingResources(
        lessons: [
          const TrainingLesson(
            id: 'lesson',
            kind: TrainingLessonKind.theme,
            title: 'Theme',
          ),
        ],
        banks: {
          'lesson': [exercise],
        },
      );
      await cubit.hint();
      now.advance(const Duration(days: 1));
      await repository.transact(
        TrainingCourse.pilares,
        (current) => BuildDayGoals(now, TrainingCourseConfig.pilares)(
          current,
          repository.content[TrainingCourse.pilares]!,
        ),
      );
      final reopened = create();
      await reopened.load();
      expect(reopened.state.hint, true);
      expect(reopened.state.exercise!.id, exercise.id);
      await reopened.play('e2e4');
      await reopened.play('g1f3');
      expect(reopened.state.cycle!.days.single.hint, true);
      expect(reopened.state.cycle!.days.single.earned, false);
      await reopened.close();
    },
  );

  test('navigation waits for persisted result', () async {
    final gate = Completer<void>();
    repository.beforeSave = gate.future;
    final playing = cubit.play('d2d4');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.phase, TrainingExercisePhase.saving);
    expect(cubit.next(), false);
    gate.complete();
    await playing;
    expect(cubit.next(), true);
  });

  test('midnight preserves the open attempt until it finishes', () async {
    repository.content[TrainingCourse.pilares] = TrainingResources(
      lessons: [
        const TrainingLesson(
          id: 'lesson',
          kind: TrainingLessonKind.theme,
          title: 'Theme',
        ),
      ],
      banks: {
        'lesson': [exercise],
      },
    );
    await repository.update(
      TrainingCourse.pilares,
      (current) => current.copyWith(completedLessons: {'lesson': '2026-10-20'}),
    );
    now.advance(const Duration(days: 1));
    await cubit.play('d2d4');
    expect(cubit.state.phase, TrainingExercisePhase.result);
    expect(cubit.state.error, false);
    final stored = await repository.load(TrainingCourse.pilares);
    expect(stored.day!.date, '2026-10-29');
    expect(stored.cycles['lesson']!.days.single.date, '2026-10-29');
    expect(cubit.next(), true);
  });

  test('day off does not interrupt an exercise already open', () async {
    now.advance(const Duration(days: 2));
    await cubit.play('d2d4');
    expect(cubit.state.phase, TrainingExercisePhase.result);
    expect(repository.writes, 1);
    expect(
      (await repository.load(TrainingCourse.pilares)).cycles['lesson']!.days,
      hasLength(1),
    );
    expect(cubit.next(), true);
  });

  test('Friday hint survives weekend JSON with empty goals and resumes Monday once', () {
    final nextLesson = TrainingGoal(kind: GoalKind.lesson, ref: 'nextLesson');
    final doneLesson = TrainingGoal(
      kind: GoalKind.lesson,
      ref: 'doneLesson',
      done: true,
    );
    final resources = TrainingResources(
      lessons: [
        const TrainingLesson(
          id: 'lesson',
          kind: TrainingLessonKind.theme,
          title: 'Theme',
        ),
        const TrainingLesson(
          id: 'nextLesson',
          kind: TrainingLessonKind.theme,
          title: 'Next',
        ),
        const TrainingLesson(
          id: 'doneLesson',
          kind: TrainingLessonKind.theme,
          title: 'Done',
        ),
      ],
      banks: {
        'lesson': [exercise],
      },
    );
    final clock = FakeNow(DateTime(2026, 10, 30, 12));
    final build = BuildDayGoals(clock, TrainingCourseConfig.pilares);
    var current = saved().copyWith(
      completedLessons: {'lesson': '2026-10-20', 'doneLesson': '2026-10-20'},
      day: DayGoals(
        date: '2026-10-30',
        studyDay: true,
        goals: [goal.withHint(), nextLesson, doneLesson],
      ),
    );
    final legacy = current.toJson()..remove('deferredGoals');
    expect(TrainingState.fromJson(legacy).deferredGoals, isEmpty);
    for (var i = 0; i < 2; i++) {
      clock.advance(const Duration(days: 1));
      current = build(current, resources);
      current = TrainingState.fromJson(current.toJson());
      expect(current.day!.studyDay, false);
      expect(current.day!.goals, isEmpty);
      expect(current.day!.remaining, 0);
      expect(current.deferredGoals.length, 2);
      expect(
        current.deferredGoals.firstWhere((g) => g.key == goal.key).hintUsed,
        true,
      );
      expect(current.cycles['lesson']!.days, isEmpty);
    }
    clock.advance(const Duration(days: 1));
    current = build(current, resources);
    expect(current.day!.date, '2026-11-02');
    expect(
      current.day!.goals.where((g) => g.kind == GoalKind.lesson).length,
      1,
    );
    expect(
      current.day!.goals.where((g) => g.key == goal.key).single.hintUsed,
      true,
    );
    expect(current.deferredGoals, isEmpty);
    expect(current.cycles['lesson']!.days, isEmpty);
  });

  test('leaving during result write completes persistence without emitting after close', () async {
    final gate = Completer<void>();
    repository.beforeSave = gate.future;
    final pending = cubit.play('d2d4');
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    gate.complete();
    await pending;
    expect((await repository.load(TrainingCourse.pilares)).day!.allDone, true);
  });

  test('seventh result opens end with rule-selected phase', () async {
    await repository.update(
      TrainingCourse.pilares,
      (_) => saved(
        cycle: ThemeCycle(
          lessonId: 'lesson',
          startedOn: '2026-10-20',
          days: [
            for (var i = 0; i < 6; i++)
              ThemeDay(
                date: '2026-10-${20 + i}',
                exerciseId: 'old$i',
                stars: [1, 1, 2, 2, 3, 3][i],
                correct: true,
              ),
          ],
        ),
      ),
    );
    await cubit.load();
    await cubit.play('e2e4');
    await cubit.play('g1f3');
    expect(cubit.next(), false);
    expect(cubit.state.phase, TrainingExercisePhase.end);
    expect(cubit.state.cycle!.phase, ThemePhase.firm);
  });

  for (final entry in <({List<int> points, ThemePhase phase, int score})>[
    (points: [1, 1, 2, 2, 3, 1], phase: ThemePhase.firm, score: 73),
    (points: [1, 1, 1, 1, 1, 1], phase: ThemePhase.reinforce, score: 47),
    (points: [1, 1, 1, 0, 0, 0], phase: ThemePhase.redo, score: 27),
  ]) {
    test('cycle score ${entry.score} produces ${entry.phase}', () async {
      await repository.update(
        TrainingCourse.pilares,
        (_) => saved(
          cycle: ThemeCycle(
            lessonId: 'lesson',
            startedOn: '2026-10-20',
            days: [
              for (var i = 0; i < 6; i++)
                ThemeDay(
                  date: '2026-10-${20 + i}',
                  exerciseId: 'old$i',
                  stars: entry.points[i] == 0 ? 1 : entry.points[i],
                  correct: entry.points[i] != 0,
                ),
            ],
          ),
        ),
      );
      await cubit.load();
      await cubit.play('e2e4');
      await cubit.play('g1f3');
      expect(cubit.state.cycle!.score, entry.score);
      expect(cubit.state.cycle!.phase, entry.phase);
      cubit.next();
      expect(cubit.state.phase, TrainingExercisePhase.end);
      if (entry.phase == ThemePhase.redo) {
        final restarted = ThemeCycle(
          lessonId: 'lesson',
          startedOn: '2026-10-29',
        );
        await repository.update(
          TrainingCourse.pilares,
          (s) => s.copyWith(cycles: {...s.cycles, 'lesson': restarted}),
        );
        expect(await cubit.reinforceFirst(), false);
        expect(
          (await repository.load(TrainingCourse.pilares)).cycles['lesson']!
              .toJson(),
          restarted.toJson(),
        );
        expect(cubit.state.phase, TrainingExercisePhase.expired);
      }
    });
  }

  test(
    'reinforcement 4/7 produces redo-after and stays pending on not now',
    () async {
      final reinforceGoal = TrainingGoal(
        kind: GoalKind.reinforce,
        ref: 'lesson',
        itemId: 'e',
      );
      await repository.update(
        TrainingCourse.pilares,
        (_) => saved(
          selected: reinforceGoal,
          cycle: ThemeCycle(
            lessonId: 'lesson',
            startedOn: '2026-10-20',
            phase: ThemePhase.reinforce,
            reinforcement: ['a', 'b', 'c', 'd', 'f', 'g', 'e'],
            days: [
              for (var i = 0; i < 6; i++)
                ThemeDay(
                  date: '2026-10-${20 + i}',
                  exerciseId: 'old$i',
                  stars: 1,
                  correct: i < 3,
                  phase: ThemePhase.reinforce,
                ),
            ],
          ),
        ),
      );
      final other = TrainingExerciseCubit(
        repository: repository,
        config: TrainingCourseConfig.pilares,
        now: now,
        goalKey: reinforceGoal.key,
      );
      await other.load();
      await other.play('e2e4');
      await other.play('g1f3');
      expect(other.state.cycle!.reinforceScore, 57);
      expect(other.state.cycle!.phase, ThemePhase.redo);
      expect(other.next(), false);
      expect(other.state.reinforcement, true);
      expect(await other.reinforceFirst(), false);
      await other.close();
      expect(
        (await repository.load(TrainingCourse.pilares)).cycles['lesson']!.phase,
        ThemePhase.redo,
      );
    },
  );

  test(
    'explicit initial alternative accepted without invented continuation',
    () {
      final runner = PlayTrainingExercise(
        TrainingExercise(
          id: 'alternative',
          stars: 1,
          fen: exercise.fen,
          solution: exercise.solution,
          alternatives: ['d2d4'],
        ),
      );
      final result = runner.play(exercise.fen, 0, 'd2d4');
      expect(result.done, true);
      expect(result.correct, true);
      expect(result.lastMove, 'd2d4');
      expect(result.fen, isNot(contains(' e3 '))); // No main-line continuation.
    },
  );

  test('invalid bank line is rejected before accepting attempts', () {
    expect(
      () => PlayTrainingExercise(
        TrainingExercise(
          id: 'bad',
          stars: 1,
          fen: exercise.fen,
          solution: ['e2e5'],
        ),
      ),
      throwsFormatException,
    );
  });
}
