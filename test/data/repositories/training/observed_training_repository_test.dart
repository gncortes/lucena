import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/observed_training_repository.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';

void main() {
  test(
    'command and qualifying observation publish one durable state',
    () async {
      final inner = FakeTrainingRepository(
        content: {TrainingCourse.escola: TrainingResources()},
      );
      addTearDown(inner.dispose);
      final gate = Completer<void>();
      inner.beforeSave = gate.future;
      final repository = ObservedTrainingRepository(
        inner,
        observers: {
          TrainingCourse.escola: (state, _) async => state.day?.next == null
              ? state
              : state.copyWith(
                  day: state.day!.copyWith(
                    goals: [
                      for (final goal in state.day!.goals) goal.complete(),
                    ],
                  ),
                ),
        },
      );
      final published = <bool>[];
      final subscription = repository.changes.listen(
        (s) => published.add(s.day!.allDone),
      );
      addTearDown(subscription.cancel);
      final saving = repository.update(
        TrainingCourse.escola,
        (s) => s.copyWith(
          onboardingDone: true,
          day: DayGoals(
            date: '2026-10-29',
            studyDay: true,
            goals: [
              TrainingGoal(
                kind: GoalKind.stars,
                ref: 'pieces.rook',
                itemId: 'easy',
              ),
            ],
          ),
        ),
      );
      await Future<void>.value();
      expect(published, isEmpty);
      gate.complete();
      final saved = await saving;
      await Future<void>.value();
      expect(saved.day!.allDone, true);
      expect(published, [true]);
      expect(inner.writes, 1);
      expect((await repository.load(TrainingCourse.escola)).day!.allDone, true);
      expect(inner.writes, 1);
    },
  );

  test(
    'failed observation rolls the command back without erasing existing state',
    () async {
      final inner = FakeTrainingRepository(
        content: {TrainingCourse.escola: TrainingResources()},
      );
      addTearDown(inner.dispose);
      final repository = ObservedTrainingRepository(
        inner,
        observers: {
          TrainingCourse.escola: (_, _) async =>
              throw StateError('source unavailable'),
        },
      );
      await expectLater(
        repository.update(
          TrainingCourse.escola,
          (s) => s.copyWith(onboardingDone: true),
        ),
        throwsStateError,
      );
      expect((await inner.load(TrainingCourse.escola)).onboardingDone, false);
      expect(inner.writes, 0);
      expect(
        (await repository.load(TrainingCourse.pilares)).onboardingDone,
        false,
      );
    },
  );
}
