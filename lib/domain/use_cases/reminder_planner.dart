import '../models/reminder.dart';
import '../models/streak.dart';
import '../models/week_summary.dart';
import 'streak_rules.dart';

/// Quais lembretes locais agendar (E1.23, ponto aberto 3 da E1.21): no máximo
/// um por dia, na hora escolhida em Avisos.
///
/// - Hoje, se nada foi jogado: "sua sequência acaba hoje" com 2 dias ou mais;
///   senão "Continue a lição" com aula em andamento.
/// - Amanhã: a sequência, se hoje já contou (com 2 dias ou mais); senão a
///   aula. Sem jogar hoje, a sequência acaba à meia-noite e não há o que
///   lembrar amanhã.
/// - No domingo da semana, o resumo no lugar do lembrete do dia, se houve
///   partida na semana.
///
/// O app replaneja ao abrir, ao voltar, ao ir para segundo plano e a cada
/// partida ou aula: o que muda o estado muda o plano.
abstract final class ReminderPlanner {
  /// Sequência mínima para o lembrete dela.
  static const minStreak = 2;

  static List<PlannedReminder> plan({
    required DateTime now,
    required bool enabled,
    required int minutes,
    required Streak streak,
    PausedLesson? lesson,
    WeekSummary? week,
  }) {
    if (!enabled) return const [];
    final today = StreakRules.day(now);
    final days = StreakRules.week(now);
    final plan = <PlannedReminder>[];
    for (var offset = 0; ; offset++) {
      final day = DateTime(today.year, today.month, today.day + offset);
      if (!days.contains(day)) break;
      final at = DateTime(
        day.year,
        day.month,
        day.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (!at.isAfter(now)) continue;
      final reminder = _reminder(
        offset: offset,
        at: at,
        sunday: day.weekday == DateTime.sunday,
        streak: streak,
        lesson: lesson,
        week: week,
      );
      if (reminder != null) plan.add(reminder);
    }
    return plan;
  }

  static PlannedReminder? _reminder({
    required int offset,
    required DateTime at,
    required bool sunday,
    required Streak streak,
    PausedLesson? lesson,
    WeekSummary? week,
  }) {
    if (sunday && week != null && week.finals > 0) {
      return PlannedReminder(kind: ReminderKind.week, at: at, week: week);
    }
    final ending = switch (offset) {
      0 => !streak.activeToday,
      1 => streak.activeToday,
      _ => false,
    };
    if (ending && streak.current >= minStreak) {
      return PlannedReminder(
        kind: ReminderKind.streak,
        at: at,
        streakDays: streak.current,
      );
    }
    final lessonDay = switch (offset) {
      0 => !streak.activeToday,
      1 => true,
      _ => false,
    };
    if (lessonDay && lesson != null) {
      return PlannedReminder(kind: ReminderKind.lesson, at: at, lesson: lesson);
    }
    return null;
  }
}
