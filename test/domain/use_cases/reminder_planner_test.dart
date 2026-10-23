import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/reminder.dart';
import 'package:lucena/domain/models/streak.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/domain/use_cases/reminder_planner.dart';

void main() {
  // Quinta, 22 de outubro de 2026: a semana vai de 19 a 25.
  final thursday = DateTime(2026, 10, 22, 9);
  const seven = 19 * 60;
  const lesson = PausedLesson(
    lessonId: 'lucena',
    title: 'A posição de Lucena',
    chapter: 3,
    total: 6,
    partId: 'ponte',
    stage: 2,
  );
  WeekSummary week(int finals) => WeekSummary(
    monday: DateTime(2026, 10, 19),
    finals: finals,
    perDay: [finals, 0, 0, 0, 0, 0, 0],
    ratingFrom: 1152,
    ratingTo: 1192,
    streakDays: 3,
    firstTry: 9,
  );
  Streak streak(int current, {bool today = false}) =>
      Streak(current: current, record: current, activeToday: today);

  List<(ReminderKind, int)> kinds(List<PlannedReminder> plan) => [
    for (final reminder in plan) (reminder.kind, reminder.at.day),
  ];

  test('com a chave desligada, nada', () {
    final plan = ReminderPlanner.plan(
      now: thursday,
      enabled: false,
      minutes: seven,
      streak: streak(5),
      lesson: lesson,
      week: week(4),
    );
    expect(plan, isEmpty);
  });

  test('sem jogar hoje: a sequência hoje e o resumo no domingo', () {
    final plan = ReminderPlanner.plan(
      now: thursday,
      enabled: true,
      minutes: seven,
      streak: streak(3),
      week: week(4),
    );
    expect(kinds(plan), [(ReminderKind.streak, 22), (ReminderKind.week, 25)]);
    expect(plan.first.at, DateTime(2026, 10, 22, 19));
    expect(plan.first.streakDays, 3);
  });

  test('já jogou hoje: o de hoje sai e a sequência fica para amanhã', () {
    final plan = ReminderPlanner.plan(
      now: thursday,
      enabled: true,
      minutes: seven,
      streak: streak(3, today: true),
      lesson: lesson,
      week: week(4),
    );
    expect(kinds(plan), [(ReminderKind.streak, 23), (ReminderKind.week, 25)]);
  });

  test('sequência de 1 dia não avisa; a aula parada avisa hoje e amanhã', () {
    final plan = ReminderPlanner.plan(
      now: thursday,
      enabled: true,
      minutes: seven,
      streak: streak(1),
      lesson: lesson,
    );
    expect(kinds(plan), [(ReminderKind.lesson, 22), (ReminderKind.lesson, 23)]);
    expect(plan.first.lesson, lesson);
  });

  test('depois da hora, hoje não tem mais lembrete', () {
    final plan = ReminderPlanner.plan(
      now: DateTime(2026, 10, 22, 20),
      enabled: true,
      minutes: seven,
      streak: streak(1),
      lesson: lesson,
    );
    expect(kinds(plan), [(ReminderKind.lesson, 23)]);
  });

  test('trocar a hora muda a hora de todos', () {
    final plan = ReminderPlanner.plan(
      now: thursday,
      enabled: true,
      minutes: 21 * 60 + 30,
      streak: streak(3),
      week: week(4),
    );
    expect(plan.map((r) => r.at), [
      DateTime(2026, 10, 22, 21, 30),
      DateTime(2026, 10, 25, 21, 30),
    ]);
  });

  test('no domingo, o resumo fica no lugar do lembrete do dia', () {
    final plan = ReminderPlanner.plan(
      now: DateTime(2026, 10, 25, 9),
      enabled: true,
      minutes: seven,
      streak: streak(4),
      lesson: lesson,
      week: week(4),
    );
    expect(kinds(plan), [(ReminderKind.week, 25)]);
  });

  test('semana sem finais: o domingo segue a regra do dia', () {
    final plan = ReminderPlanner.plan(
      now: DateTime(2026, 10, 25, 9),
      enabled: true,
      minutes: seven,
      streak: streak(4),
      week: week(0),
    );
    expect(kinds(plan), [(ReminderKind.streak, 25)]);
  });

  test('no máximo um por dia', () {
    final plan = ReminderPlanner.plan(
      now: DateTime(2026, 10, 19, 9),
      enabled: true,
      minutes: seven,
      streak: streak(5),
      lesson: lesson,
      week: week(4),
    );
    final days = [for (final reminder in plan) reminder.at.day];
    expect(days.toSet().length, days.length);
  });
}
