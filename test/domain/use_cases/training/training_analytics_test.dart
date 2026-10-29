import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/analytics_event.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/training_analytics.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  final now = FakeNow(DateTime(2026, 10, 29, 12));
  TrainingState saved(
    TrainingCourse course,
    List<TrainingGoal> goals, {
    bool doubled = false,
  }) => TrainingState(
    course: course,
    installSeed: 'test',
    day: DayGoals(
      date: '2026-10-29',
      studyDay: true,
      goals: goals,
      doubled: doubled,
    ),
  );
  for (final shown in [true, false]) {
    test(
      'graded feedback flag persists and completion is emitted once: $shown',
      () async {
        final events = <AnalyticsEvent>[];
        final analytics = TrainingAnalytics(
          now: now,
          log: (event) async => events.add(event),
        );
        final goal = TrainingGoal(
          kind: GoalKind.exercise,
          ref: 'lesson',
          itemId: 'e',
        );
        final before = saved(TrainingCourse.pilares, [goal]);
        await analytics.startGoal(before, goal);
        analytics.result(TrainingCourse.pilares, goal.key, correct: false);
        final error = TrainingExerciseError(
          fen: '8/8/8/8/8/8/8/8 w - - 0 1',
          cursor: 2,
          wrongMove: 'a1a2',
          feedbackShown: shown,
        );
        final after = TrainingState.fromJson(
          saved(TrainingCourse.pilares, [
            goal.withExerciseError(error).complete(),
          ]).toJson(),
        );
        expect(after.day!.goals.single.exerciseError!.cursor, 2);
        await analytics.onSaved(before, after);
        await analytics.onSaved(after, after);
        final end = events.where((event) => event.name == 'treino_meta_fim');
        expect(end, hasLength(1));
        expect(end.single.params['fala_erro'], shown ? 'sim' : 'nao');
        expect(end.single.params['acertou'], 'nao');
      },
    );
  }
  for (final course in TrainingCourse.values) {
    for (final kind in GoalKind.values) {
      test(
        '$course $kind completion preserves context and dedups durable replay',
        () async {
          final events = <AnalyticsEvent>[];
          final analytics = TrainingAnalytics(
            now: now,
            log: (e) async {
              events.add(e);
            },
          );
          final goal = TrainingGoal(
            kind: kind,
            ref: 'lesson1',
            stars: kind == GoalKind.stars ? 2 : 0,
            mock: true,
          );
          final before = saved(course, [goal]);
          await analytics.startGoal(before, goal, origin: 'home');
          await analytics.startGoal(
            before,
            goal,
          ); // Screen loading must preserve route origin/time.
          now.advance(const Duration(seconds: 11));
          analytics.result(
            course,
            goal.key,
            correct: true,
            hints: 1,
            points: 3,
          );
          final after = saved(course, [goal.withHint().complete()]);
          await analytics.onSaved(before, after);
          await analytics.onSaved(after, after);
          final starts = events.where((e) => e.name == 'treino_meta_inicio');
          final ends = events.where((e) => e.name == 'treino_meta_fim');
          expect(starts, hasLength(1));
          expect(ends, hasLength(1));
          expect(ends.single.params, containsPair('curso', course.name));
          expect(ends.single.params, containsPair('origem', 'home'));
          expect(ends.single.params, containsPair('tempo_s', 11));
          expect(ends.single.params, containsPair('acertou', 'nao'));
          expect(ends.single.params, containsPair('mock', 'sim'));
          expect(ends.single.params, containsPair('dicas', 1));
          if (kind == GoalKind.stars) expect(ends.single.params['pontos'], 3);
          expect(
            events.where((e) => e.name == 'treino_dia_completo'),
            hasLength(1),
          );
        },
      );
    }
  }
  test('course contexts do not collide; reload fallback and doubled second completion', () async {
    final events = <AnalyticsEvent>[];
    final analytics = TrainingAnalytics(
      now: now,
      log: (e) async {
        events.add(e);
      },
    );
    final goal = TrainingGoal(kind: GoalKind.lesson, ref: 'lesson1');
    final p = saved(TrainingCourse.pilares, [goal]);
    final e = saved(TrainingCourse.escola, [goal]);
    await analytics.startGoal(p, goal, origin: 'home');
    await analytics.startGoal(e, goal);
    await analytics.onSaved(
      p,
      saved(TrainingCourse.pilares, [goal.complete()]),
    );
    await analytics.onSaved(e, saved(TrainingCourse.escola, [goal.complete()]));
    expect(
      events
          .where((e) => e.name == 'treino_meta_fim')
          .map((e) => e.params['origem']),
      ['home', 'metas'],
    );
    final done = saved(TrainingCourse.pilares, [goal.complete()]);
    final extra = TrainingGoal(kind: GoalKind.extraLesson, ref: 'lesson2');
    final doubled = saved(TrainingCourse.pilares, [
      goal.complete(),
      extra,
    ], doubled: true);
    await analytics.onSaved(done, doubled);
    final second = saved(TrainingCourse.pilares, [
      goal.complete(),
      extra.complete(),
    ], doubled: true);
    await analytics.onSaved(doubled, second);
    await analytics.onSaved(second, second);
    expect(events.where((e) => e.name == 'treino_meta_dobrada'), hasLength(1));
    expect(events.last.params['dobrou'], 'sim');
  });
  test('extra lesson and off-day have no mock or content leak', () {
    final before = TrainingState(
      course: TrainingCourse.escola,
      installSeed: 'test',
    );
    final after = before.copyWith(completedLessons: {'lesson1': '2026-10-29'});
    final events = trainingAnalyticsDiff(before, after, now: now());
    expect(events.single.name, 'treino_aula_extra');
    expect(events.single.params, {
      'curso': 'escola',
      'aula_id': 'lesson1',
      'dia_folga': 'sim',
    });
    expect(trainingAnalyticsDiff(after, after, now: now()), isEmpty);
  });
  test('log failures remain best effort', () async {
    final analytics = TrainingAnalytics(
      now: now,
      log: (_) => Future.error(StateError('transport')),
    );
    await analytics.send(
      AnalyticsEvents.treinoLembreteMostrado(curso: 'pilares', atrasoMin: 3),
    );
  });
}
