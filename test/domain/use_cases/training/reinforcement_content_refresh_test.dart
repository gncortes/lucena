import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/complete_training_goal.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';

import '../../../../testing/fakes/fake_now.dart';
import 'training_rules_test.dart' as fixtures;

void main() {
  final now = FakeNow(DateTime(2026, 10, 26, 12));
  final build = BuildDayGoals(now, TrainingCourseConfig.pilares);
  TrainingState state({
    ThemePhase phase = ThemePhase.reinforce,
    List<String> ids = const ['removed'],
    DayGoals? day,
  }) => fixtures.initial().copyWith(
    completedLessons: const {'theme1': '2026-10-23'},
    cycles: {
      'theme1': ThemeCycle(
        lessonId: 'theme1',
        startedOn: '2026-10-23',
        phase: phase,
        reinforcement: ids,
        days: const [
          ThemeDay(
            date: '2026-10-24',
            exerciseId: 'old',
            stars: 1,
            correct: false,
          ),
        ],
      ),
    },
    day: day,
  );
  TrainingResources resources({List<String>? ids}) => TrainingResources(
    lessons: const [fixtures.first, fixtures.second],
    banks: {
      if (ids != null)
        'theme1': [for (final id in ids) fixtures.exercise(id, 1)],
    },
  );

  for (final phase in [ThemePhase.cycle, ThemePhase.reinforce]) {
    for (final ids in <List<String>?>[
      null,
      [],
      ['unrelated'],
    ]) {
      if (phase == ThemePhase.cycle && ids?.isNotEmpty == true) continue;
      test('$phase bank $ids yields real redo without changing history', () {
        final before = state(phase: phase);
        final next = build(before, resources(ids: ids));
        expect(next.cycles['theme1']!.phase, ThemePhase.redo);
        expect(next.cycles['theme1']!.days, before.cycles['theme1']!.days);
        expect(next.completedLessons, before.completedLessons);
        expect(
          next.day!.goals.any(
            (g) => g.ref == 'theme1' && g.kind == GoalKind.redo,
          ),
          isTrue,
        );
      });
    }
  }
  test('empty frozen reinforcement also uses redo with a populated bank', () {
    expect(
      build(state(ids: []), resources(ids: ['valid'])).cycles['theme1']!.phase,
      ThemePhase.redo,
    );
  });
  test('removed first ID skips to the next valid frozen ID', () {
    final next = build(
      state(ids: ['removed', 'valid']),
      resources(ids: ['valid']),
    );
    expect(next.cycles['theme1']!.phase, ThemePhase.reinforce);
    expect(
      next.day!.goals.where((g) => g.ref == 'theme1').single.itemId,
      'valid',
    );
    final completed = CompleteTrainingGoal(now).exercise(
      next,
      resources(ids: ['valid']),
      next.day!.goals.where((g) => g.ref == 'theme1').single.key,
      correct: true,
    );
    final refreshed = build(completed, resources(ids: ['valid']));
    expect(refreshed.cycles['theme1']!.phase, ThemePhase.redo);
    expect(refreshed.cycles['theme1']!.days, hasLength(2));
  });
  test('same-day replacement preserves done attempts and other goals', () {
    final done = TrainingGoal(
      kind: GoalKind.reinforce,
      ref: 'theme1',
      itemId: 'old',
      done: true,
    );
    final lesson = TrainingGoal(kind: GoalKind.lesson, ref: 'theme2');
    final original = state(
      day: DayGoals(
        date: '2026-10-26',
        studyDay: true,
        doubled: true,
        goals: [
          done,
          lesson,
          TrainingGoal(
            kind: GoalKind.reinforce,
            ref: 'theme1',
            itemId: 'removed',
          ),
        ],
      ),
    );
    final next = build(original, resources());
    expect(next.cycles['theme1']!.phase, ThemePhase.redo);
    expect(next.day!.doubled, isTrue);
    expect(next.day!.goals.take(2), [done, lesson]);
    expect(next.day!.goals.last.kind, GoalKind.redo);
    expect(next.cycles['theme1']!.days, original.cycles['theme1']!.days);
    final redone = CompleteTrainingLesson(now, TrainingCourseConfig.pilares)(
      next,
      resources(),
      fixtures.first,
      redo: next.cycles['theme1']!.phase == ThemePhase.redo,
    );
    expect(redone.cycles['theme1']!.phase, ThemePhase.cycle);
    expect(redone.cycles['theme1']!.startedOn, '2026-10-26');
    expect(redone.day!.goals.last.done, isTrue);
    final tomorrow = BuildDayGoals(
      FakeNow(DateTime(2026, 10, 27, 12)),
      TrainingCourseConfig.pilares,
    )(redone, resources(ids: ['restored']));
    expect(tomorrow.cycles['theme1']!.phase, ThemePhase.cycle);
    expect(
      tomorrow.day!.goals.where((goal) => goal.ref == 'theme1').single.kind,
      GoalKind.exercise,
    );
    expect(tomorrow.cycles['theme1']!.days, isEmpty);
  });
  test('same-day pending removed ID is replaced with valid ID', () {
    final next = build(
      state(
        ids: ['removed', 'valid'],
        day: DayGoals(
          date: '2026-10-26',
          studyDay: true,
          goals: [
            TrainingGoal(
              kind: GoalKind.reinforce,
              ref: 'theme1',
              itemId: 'removed',
            ),
          ],
        ),
      ),
      resources(ids: ['valid']),
    );
    expect(next.day!.goals.single.itemId, 'valid');
  });
  test(
    'legacy empty day gains redo and deferred invalid goal is reconciled',
    () {
      final original = state(day: DayGoals(date: '2026-10-26', studyDay: true))
          .copyWith(
            deferredGoals: [
              TrainingGoal(
                kind: GoalKind.reinforce,
                ref: 'theme1',
                itemId: 'removed',
              ),
            ],
          );
      final next = build(original, resources());
      expect(next.day!.goals.single.kind, GoalKind.redo);
      expect(next.deferredGoals, isEmpty);
      expect(build(next, resources()).toJson(), next.toJson());
    },
  );
  for (final kind in [GoalKind.exercise, GoalKind.reinforce]) {
    test('completed $kind keeps today complete after bank removal', () {
      final done = TrainingGoal(
        kind: kind,
        ref: 'theme1',
        itemId: 'removed',
        done: true,
      );
      final original = state(
        phase: kind == GoalKind.exercise
            ? ThemePhase.cycle
            : ThemePhase.reinforce,
        day: DayGoals(date: '2026-10-26', studyDay: true, goals: [done]),
      );
      final next = build(original, resources());
      expect(next.cycles['theme1']!.phase, ThemePhase.redo);
      expect(next.day!.allDone, isTrue);
      expect(next.day!.remaining, 0);
      expect(next.day!.goals, [done]);
      expect(next.cycles['theme1']!.days, original.cycles['theme1']!.days);
      expect(build(next, resources()).toJson(), next.toJson());
      final tomorrow = BuildDayGoals(
        FakeNow(DateTime(2026, 10, 27, 12)),
        TrainingCourseConfig.pilares,
      )(next, resources());
      final redo = tomorrow.day!.goals
          .where((goal) => goal.ref == 'theme1')
          .single;
      expect(redo.kind, GoalKind.redo);
      expect(redo.done, isFalse);
    });
  }
  test('pending redo belongs only to today after deferred reconciliation', () {
    final pending = TrainingGoal(
      kind: GoalKind.reinforce,
      ref: 'theme1',
      itemId: 'removed',
    );
    final other = TrainingGoal(kind: GoalKind.lesson, ref: 'theme2');
    final original = state(
      day: DayGoals(date: '2026-10-26', studyDay: true, goals: [pending]),
    ).copyWith(deferredGoals: [pending, other]);
    final next = build(original, resources());
    expect(next.day!.goals.single.kind, GoalKind.redo);
    expect(next.deferredGoals, [other]);
    expect(build(next, resources()).toJson(), next.toJson());
  });
  test(
    'valid frozen pending goal retains hint and completed state is untouched',
    () {
      final pending = TrainingGoal(
        kind: GoalKind.reinforce,
        ref: 'theme1',
        itemId: 'valid',
        hintUsed: true,
      );
      final original = state(
        ids: ['valid'],
        day: DayGoals(date: '2026-10-26', studyDay: true, goals: [pending]),
      );
      final next = build(original, resources(ids: ['valid']));
      expect(next.day!.goals.single, same(pending));
      expect(next.cycles['theme1'], same(original.cycles['theme1']));
    },
  );
}
