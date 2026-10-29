import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/complete_training_goal.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/double_training_goals.dart';
import 'package:lucena/domain/use_cases/training/training_date.dart';

import '../fakes/fake_now.dart';
import '../fakes/fake_course_training_repository.dart';
import 'mock_exercise_bank.dart';

/// Large deterministic fixture, shared by widget, Patrol and screenshot tests.
/// School support is added with T85.14, using the existing challenge fakes.
final class TrainingScenarioBuilder {
  TrainingScenarioBuilder(this.course, {DateTime? date})
    : now = FakeNow(date ?? DateTime(2026, 10, 26, 12));
  final TrainingCourse course;
  final FakeNow now;
  TrainingCourseConfig get config => TrainingCourseConfig.pilares;
  TrainingResources get content => TrainingResources(
    lessons: [
      for (var i = 1; i <= 12; i++)
        TrainingLesson(
          id: 'theme$i',
          kind: TrainingLessonKind.theme,
          title: 'Tema $i',
          summary: 'Resumo $i',
          group: 'Capítulo $i',
        ),
      for (var i = 1; i <= 4; i++)
        TrainingLesson(
          id: 'opening$i',
          kind: TrainingLessonKind.opening,
          title: 'Abertura $i',
          group: 'Aberturas',
        ),
    ],
    banks: {
      for (var i = 1; i <= 12; i++)
        'theme$i': MockExerciseBank.forLesson('theme$i'),
    },
    openings: {
      for (var i = 1; i <= 4; i++)
        'opening$i': [
          OpeningTrecho(
            id: 't1',
            title: 'Linha 1',
            moves: ['d2d4', 'd7d5', 'c1f4'],
            mock: true,
          ),
          OpeningTrecho(
            id: 't2',
            title: 'Linha 2',
            moves: ['d2d4', 'g8f6'],
            mock: true,
          ),
        ],
    },
  );

  TrainingState large({int cycleDay = 1, bool dayOff = false}) {
    if (course != TrainingCourse.pilares) {
      throw StateError('School fixture is not configured yet');
    }
    if (cycleDay < 1 || cycleDay > 7) throw RangeError.range(cycleDay, 1, 7);
    final data = content;
    const started = '2026-10-01';
    final cycles = <String, ThemeCycle>{};
    for (var i = 1; i <= 7; i++) {
      final days = <ThemeDay>[];
      final used = <int, int>{1: 0, 2: 0, 3: 0};
      for (var d = 1; d < cycleDay; d++) {
        final stars = [1, 1, 2, 2, 3, 3, 3][d - 1];
        final exercise = data.banks['theme$i']!
            .where((e) => e.stars == stars)
            .elementAt(used[stars]!);
        used[stars] = used[stars]! + 1;
        days.add(
          ThemeDay(
            date: '2026-10-${(d + 1).toString().padLeft(2, '0')}',
            exerciseId: exercise.id,
            stars: stars,
            correct: true,
            mock: true,
          ),
        );
      }
      cycles['theme$i'] = ThemeCycle(
        lessonId: 'theme$i',
        startedOn: started,
        level: [1, 1, 2, 2, 3, 3, 3][cycleDay - 1],
        streak: (cycleDay - 1) % 2,
        days: days,
      );
    }
    cycles['theme8'] = ThemeCycle(
      lessonId: 'theme8',
      startedOn: started,
      phase: ThemePhase.reinforce,
      reinforcement: data.banks['theme8']!.map((e) => e.id),
    );
    final state = TrainingState(
      course: course,
      installSeed: 'large-fixture',
      onboardingDone: true,
      plan: TrainingPlan(weekdays: dayOff ? 0 : 127),
      completedLessons: {
        for (var i = 1; i <= 8; i++) 'theme$i': started,
        for (var i = 1; i <= 4; i++) 'opening$i': started,
      },
      cycles: cycles,
      openings: {
        for (var i = 1; i <= 4; i++)
          'opening$i': OpeningTrack(lessonId: 'opening$i', startedOn: started),
      },
    );
    return BuildDayGoals(now, config)(state, data);
  }

  TrainingState missed({int cycleDay = 1}) {
    final state = large(cycleDay: cycleDay);
    now.advance(const Duration(days: 1));
    return BuildDayGoals(now, config)(state, content);
  }

  TrainingState allDone() {
    var state = large();
    for (final goal in state.day!.goals) {
      if (goal.kind == GoalKind.exercise || goal.kind == GoalKind.reinforce) {
        state = CompleteTrainingGoal(now)
            .exercise(state, content, goal.key, correct: true);
      } else if (goal.kind == GoalKind.openings) {
        for (final id in goal.items.keys) {
          state = CompleteTrainingGoal(now)
              .opening(state, content, id, [true, true]);
        }
      } else if (goal.kind == GoalKind.lesson) {
        state = CompleteTrainingLesson(now, config)(
          state,
          content,
          content.lessons.firstWhere((l) => l.id == goal.ref),
        );
      }
    }
    return state;
  }

  TrainingState doubled() {
    final done = allDone();
    final extra = content.lessons.firstWhere((l) => l.id == 'theme10');
    final state = CompleteTrainingLesson(now, config)(done, content, extra);
    return DoubleTrainingGoals(now, config)(state, content);
  }

  FakeTrainingRepository repository(TrainingState state) =>
      FakeTrainingRepository(
        states: {course: state},
        content: {course: content},
      );
  String get date => trainingDate(now());
}
