import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/training_goal_counts.dart';
import 'package:lucena/domain/use_cases/training/training_reminder.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  test(
    'opening cards count individually and yesterday is not today completion',
    () {
      final state = TrainingState(
        course: TrainingCourse.pilares,
        onboardingDone: true,
        installSeed: 'counts',
        day: DayGoals(
          date: '2026-10-30',
          studyDay: true,
          goals: [
            TrainingGoal(kind: GoalKind.lesson, ref: 'lesson', done: true),
            TrainingGoal(kind: GoalKind.exercise, ref: 'theme'),
            TrainingGoal(
              kind: GoalKind.openings,
              ref: 'openings',
              items: {'london': 'p2', 'slav': 'p3'},
            ),
          ],
        ),
        openings: {
          'london': OpeningTrack(
            lessonId: 'london',
            startedOn: '2026-10-01',
            doneTrechos: {'p2': '2026-10-30'},
          ),
          'slav': OpeningTrack(
            lessonId: 'slav',
            startedOn: '2026-10-01',
            doneTrechos: {'p3': '2026-10-29'},
          ),
        },
      );
      expect(trainingGoalCounts(state), (total: 4, remaining: 2));
      final restored = TrainingState.fromJson(state.toJson());
      expect(trainingGoalCounts(restored), (total: 4, remaining: 2));
      expect(
        trainingReminder(
          restored,
          FakeNow(DateTime(2026, 10, 30, 12)),
        )!.text.arguments,
        {'n': 2},
      );
    },
  );
}
