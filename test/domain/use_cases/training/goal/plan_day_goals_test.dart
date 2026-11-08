import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';

import '../../../../../testing/fakes/fake_now.dart';
import 'goal_rules_test.dart' show course;

void main() {
  TrainingState state({StudyPlan? plan}) => TrainingState(
    course: TrainingCourse.pilares,
    installSeed: 's',
    onboardingDone: true,
    plan: const TrainingPlan(minutes: 60),
    studyPlan: plan,
  );

  List<String> lessonsOf(TrainingState s) => [
    for (final g in s.day!.goals)
      if (g.kind == GoalKind.lesson) g.ref,
  ];

  final build = BuildDayGoals(
    FakeNow(DateTime(2026, 11, 4, 12)),
    TrainingCourseConfig.pilares,
  );

  test('sem plano, as metas seguem a ordem do curso', () {
    final day = build(state(), course());
    expect(lessonsOf(day).first, 'c1.l1');
  });

  test('com plano, as metas saem dos capítulos da semana atual', () {
    final plan = StudyPlan(
      createdOn: '2026-11-04',
      chapterIds: const ['c4', 'c1'],
      weeks: [
        PlanWeek(
          start: '2026-11-02',
          end: '2026-11-08',
          chapterIds: const ['c4'],
        ),
        PlanWeek(
          start: '2026-11-09',
          end: '2026-11-15',
          chapterIds: const ['c1'],
        ),
      ],
    );
    final lessons = lessonsOf(build(state(plan: plan), course()));
    expect(lessons, isNotEmpty);
    expect(lessons.every((id) => id.startsWith('c4.')), isTrue);
    expect(lessons.first, 'c4.l1');
  });
}
