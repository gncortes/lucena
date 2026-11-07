import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/goal/training_objective.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/lesson_end_steps.dart';

import 'goal/goal_rules_test.dart' show course;

String label(int n, String title) => '$n · $title';

TrainingState planned({required bool dayDone}) => TrainingState(
  course: TrainingCourse.pilares,
  installSeed: 's',
  objective: const TrainingObjective(
    kind: ObjectiveKind.tournament,
    setOn: '2026-11-04',
    tournamentDate: '2026-11-25',
  ),
  studyPlan: StudyPlan(
    createdOn: '2026-11-04',
    weeks: [
      PlanWeek(start: '2026-11-04', end: '2026-11-10', chapterIds: ['c1']),
      PlanWeek(start: '2026-11-11', end: '2026-11-17', chapterIds: ['c2']),
      PlanWeek(start: '2026-11-18', end: '2026-11-25', review: true),
    ],
    chapterIds: ['c1', 'c2'],
  ),
  completedLessons: const {
    'c1.l1': '2026-11-04',
    'c1.l2': '2026-11-05',
    'c1.l3': '2026-11-06',
  },
  day: DayGoals(
    date: '2026-11-07',
    studyDay: true,
    goals: [TrainingGoal(kind: GoalKind.exercise, ref: 'c1.l3', done: dayDone)],
  ),
);

void main() {
  final resources = course();

  test('H-LIC-50: meta do dia cumprida mostra semana, capítulo e o teste '
      'que falta', () {
    final s = dayGoalSummary(
      planned(dayDone: true),
      resources,
      '2026-11-07',
      chapterLabel: label,
    )!;
    expect(s.week, 1);
    expect(s.weekCount, 3);
    expect(s.daysLeft, 3);
    expect(s.currentChapter, '1 · Capítulo 1');
    expect((s.lessonsDone, s.lessonsTotal), (3, 3));
    expect(s.testPending, isTrue);
    expect(s.chapterProgress, [0.75, 0.0]);
    expect(s.chaptersDone, 0);
  });

  test('H-LIC-50: com meta ainda aberta ou sem plano, nada aparece', () {
    expect(
      dayGoalSummary(
        planned(dayDone: false),
        resources,
        '2026-11-07',
        chapterLabel: label,
      ),
      isNull,
    );
    final noPlan = TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 's',
      day: DayGoals(date: '2026-11-07', studyDay: true),
    );
    expect(
      dayGoalSummary(noPlan, resources, '2026-11-07', chapterLabel: label),
      isNull,
    );
  });

  test('H-LIC-51: a oferta leva o capítulo e os acertos do ciclo', () {
    final s = planned(dayDone: true).copyWith(
      cycles: {
        'c2.l1': ThemeCycle(
          lessonId: 'c2.l1',
          startedOn: '2026-11-04',
          days: const [
            ThemeDay(date: 'a', exerciseId: 'e1', stars: 3, correct: true),
            ThemeDay(date: 'b', exerciseId: 'e2', stars: 0, correct: false),
          ],
        ),
      },
    );
    expect(demoOfferFacts(s, resources, 'c2.l1'), (
      chapter: 2,
      correct: 1,
      total: 2,
    ));
    expect(demoOfferFacts(s, resources, 'c3.l1'), isNull);
  });
}
