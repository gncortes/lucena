import '../models/daily_final.dart';
import '../models/week_summary.dart';
import 'streak_rules.dart';

/// As contas do resumo da semana (E1.23).
abstract final class WeekRules {
  /// A semana de [now]: [played] são as datas das partidas terminadas,
  /// [daily] os finais do dia jogados (a primeira tentativa de cada dia).
  /// Partidas e finais fora da semana ficam de fora.
  static WeekSummary of({
    required DateTime now,
    required Iterable<DateTime> played,
    required Iterable<DailyRecord> daily,
    required int ratingFrom,
    required int ratingTo,
    required int streakDays,
  }) {
    final days = StreakRules.week(now);
    final perDay = List<int>.filled(days.length, 0);
    for (final at in played) {
      final index = days.indexOf(StreakRules.day(at));
      if (index >= 0) perDay[index]++;
    }
    var firstTry = 0;
    for (final record in daily) {
      if (!days.contains(StreakRules.day(record.date))) continue;
      firstTry += record.squares.where((s) => s == DailySquare.right).length;
    }
    return WeekSummary(
      monday: days.first,
      finals: perDay.fold(0, (sum, n) => sum + n),
      perDay: perDay,
      ratingFrom: ratingFrom,
      ratingTo: ratingTo,
      streakDays: streakDays,
      firstTry: firstTry,
    );
  }
}
