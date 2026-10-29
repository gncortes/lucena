import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/analytics_event.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/training_analytics.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../data/repositories/training/training_repository_test.dart'
    show MemoryPreferences, MemoryContent;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test('observer runs after disk only; duplicate completion on reopened repository is ignored', () async {
    final prefs = MemoryPreferences();
    final events = <AnalyticsEvent>[];
    final now = FakeNow(DateTime(2026, 10, 29));
    final analytics = TrainingAnalytics(
      now: now,
      log: (e) async {
        events.add(e);
      },
    );
    TrainingRepositoryLocal create() => TrainingRepositoryLocal(
      prefs,
      LessonContentAssets(reader: MemoryContent()),
      installSeed: 'test',
      onSaved: (before, after) {
        expect(
          prefs.values[TrainingRepositoryLocal.key(after.course)],
          isNotNull,
        );
        return analytics.onSaved(before, after);
      },
    );
    final repository = create();
    final goal = TrainingGoal(kind: GoalKind.lesson, ref: 'lesson1');
    await repository.update(
      TrainingCourse.pilares,
      (s) => s.copyWith(
        day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
      ),
    );
    prefs.fail = true;
    await expectLater(
      repository.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(day: s.day!.copyWith(goals: [goal.complete()])),
      ),
      throwsStateError,
    );
    expect(events, isEmpty);
    prefs.fail = false;
    await repository.update(
      TrainingCourse.pilares,
      (s) => s.copyWith(day: s.day!.copyWith(goals: [goal.complete()])),
    );
    final reopened = create();
    await reopened.update(
      TrainingCourse.pilares,
      (s) => s.copyWith(day: s.day!.copyWith(goals: [goal.complete()])),
    );
    expect(events.where((e) => e.name == 'treino_meta_fim'), hasLength(1));
    expect(events.where((e) => e.name == 'treino_dia_completo'), hasLength(1));
    await repository.dispose();
    await reopened.dispose();
  });
  test(
    'hanging and throwing analytics cannot block durable commands',
    () async {
      for (final hangs in [true, false]) {
        final prefs = MemoryPreferences();
        final repository = TrainingRepositoryLocal(
          prefs,
          LessonContentAssets(reader: MemoryContent()),
          installSeed: 'test',
          onSaved: (_, _) => hangs
              ? Completer<void>().future
              : Future<void>.error(StateError('analytics')),
        );
        final saved = await repository
            .update(
              TrainingCourse.pilares,
              (s) => s.copyWith(onboardingDone: true),
            )
            .timeout(const Duration(seconds: 1));
        expect(saved.onboardingDone, true);
        await repository.dispose();
      }
    },
  );
  test(
    'reminder analytics fields round-trip and clear without resetting progress',
    () {
      final at = DateTime(2026, 10, 29, 19);
      final state = TrainingState(
        course: TrainingCourse.escola,
        installSeed: 'test',
        onboardingDone: true,
        analyticsReminderAt: at,
        analyticsReminderShownAt: at,
      );
      final restored = TrainingState.fromJson(state.toJson());
      expect(restored.analyticsReminderAt, at);
      expect(restored.analyticsReminderShownAt, at);
      final cleared = restored.copyWith(analyticsReminderAt: null);
      expect(cleared.analyticsReminderAt, isNull);
      expect(cleared.analyticsReminderShownAt, at);
      expect(cleared.onboardingDone, true);
      final old = state.toJson()
        ..remove('analyticsReminderAt')
        ..remove('analyticsReminderShownAt');
      expect(TrainingState.fromJson(old).analyticsReminderAt, isNull);
    },
  );
}
