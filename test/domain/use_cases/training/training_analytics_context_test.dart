import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/school_training_observations.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/escola_follow_ups.dart';
import 'package:lucena/domain/use_cases/training/reconcile_school_training.dart';
import 'package:lucena/domain/use_cases/training/training_analytics.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';

void main() {
  final now = FakeNow(DateTime(2026, 10, 29, 12));
  test(
    'backcompat and immutable serialized attempt/segment preserve all counters',
    () {
      final old = TrainingState(
        course: TrainingCourse.escola,
        installSeed: 'test',
      ).toJson()..remove('analytics');
      final restored = TrainingState.fromJson(old);
      expect(restored.analytics.attempts, isEmpty);
      final attempt = TrainingAnalyticsAttempt(
        started: now(),
        origin: 'home',
        lessonId: 'pieces.rook',
        cycleDay: 3,
      ).result(correct: false, hints: 2, points: 4);
      final context = TrainingAnalyticsState(
        date: '2026-10-29',
        attempts: {'goal': attempt},
        segments: {
          'opening:t1': TrainingAnalyticsSegment(
            lessonId: 'opening',
            segmentId: 't1',
            started: now(),
            origin: 'home',
            total: 2,
            review: true,
            mock: true,
            errors: 3,
            back: 4,
            forward: 5,
            notation: 6,
            hints: 2,
          ),
        },
      );
      final state = restored.copyWith(analytics: context);
      final loaded = TrainingState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );
      expect(loaded.analytics.toJson(), context.toJson());
      expect(loaded.analytics.attempts['goal']!.points, 4);
      expect(() => loaded.analytics.attempts.clear(), throwsUnsupportedError);
      expect(
        () => loaded.analytics.attempts['goal']!.hintCounts.clear(),
        throwsUnsupportedError,
      );
      expect(loaded.school.speedrunOriginLesson, isNull);
    },
  );

  test(
    'School points, hints and original lesson survive a new coordinator',
    () async {
      final goal = TrainingGoal(
        kind: GoalKind.stars,
        ref: 'pieces.rook',
        stars: 2,
      );
      var stored = TrainingState(
        course: TrainingCourse.escola,
        installSeed: 'test',
        day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
      );
      final events = FakeAnalyticsRepository();
      TrainingAnalytics build() => TrainingAnalytics(
        now: now,
        log: events.log,
        read: (_) async => stored,
        write: (_, change) async {
          stored = TrainingState.fromJson(change(stored).toJson());
          return stored;
        },
      );
      var analytics = build();
      await analytics.startGoal(stored, goal, origin: 'home');
      analytics.result(
        stored.course,
        goal.key,
        correct: true,
        hints: 2,
        points: 4,
      );
      await analytics.flush(stored.course);
      analytics = build();
      await analytics.restore(stored.course);
      final after = analytics.attach(
        stored.copyWith(day: stored.day!.copyWith(goals: [goal.complete()])),
      );
      await analytics.onSaved(stored, after);
      final result = events.eventsNamed('treino_meta_fim').single.params;
      expect(result['pontos'], 4);
      expect(result['dicas'], 2);
      expect(result['origem'], 'home');
      expect(result['aula_id'], 'pieces.rook');
      expect(result['acertou'], 'nao');
    },
  );

  test('speedrun tracks actual last unlocking lesson across JSON and reconciliation', () async {
    const config = TrainingCourseConfig.escola;
    const first = TrainingLesson(
      id: 'mates.first',
      kind: TrainingLessonKind.school,
      title: 'First',
      groupId: 'firstMates',
    );
    const last = TrainingLesson(
      id: 'mates.last',
      kind: TrainingLessonKind.school,
      title: 'Last',
      groupId: 'firstMates',
    );
    final resources = TrainingResources(lessons: [first, last]);
    var state = TrainingState(
      course: config.course,
      installSeed: 'test',
      onboardingDone: true,
      day: DayGoals(
        date: '2026-10-29',
        studyDay: true,
        goals: [
          TrainingGoal(kind: GoalKind.lesson, ref: first.id),
          TrainingGoal(kind: GoalKind.lesson, ref: last.id),
        ],
      ),
    );
    state = CompleteTrainingLesson(now, config)(state, resources, first);
    state = CompleteTrainingLesson(now, config)(state, resources, last);
    expect(state.school.speedrunOriginLesson, last.id);
    final goal = state.day!.goals.firstWhere(
      (g) => g.kind == GoalKind.speedrun,
    );
    expect(goal.items['lessonId'], last.id);
    state = TrainingState.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    final redone = CompleteTrainingLesson(now, config)(
      state,
      resources,
      first,
      redo: true,
    );
    expect(redone.school.speedrunOriginLesson, last.id);
    final reconciled = ReconcileSchoolTraining(now)(
      state,
      resources,
      SchoolTrainingObservations(
        speedruns: [SchoolSpeedrunFinish(id: 'journey.mates', at: now())],
      ),
    );
    expect(reconciled.school.speedrunOriginLesson, last.id);
    expect(
      reconciled.day!.goals.firstWhere((g) => g.kind == GoalKind.speedrun).done,
      true,
    );
    final events = FakeAnalyticsRepository();
    final analytics = TrainingAnalytics(now: now, log: events.log);
    await analytics.startGoal(state, goal, origin: 'home');
    await analytics.onSaved(state, reconciled);
    expect(
      events.eventsNamed('treino_meta_inicio').single.params['aula_id'],
      last.id,
    );
    expect(
      events.eventsNamed('treino_meta_fim').single.params['aula_id'],
      last.id,
    );
    final legacy = state.copyWith(
      school: TrainingState(course: config.course, installSeed: 'test').school,
    );
    final unknown = const EscolaFollowUps()
        .build(legacy, resources, now)
        .firstWhere((g) => g.kind == GoalKind.speedrun);
    expect(unknown.items.containsKey('lessonId'), false);
    expect(lessonCode(unknown), 'nenhum');
  });
}
