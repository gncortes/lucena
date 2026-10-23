import '../models/streak.dart';

/// As contas da [Streak] a partir dos dias com atividade.
abstract final class StreakRules {
  /// O dia de [at] no fuso do aparelho, à meia-noite.
  static DateTime day(DateTime at) {
    final local = at.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static DateTime _before(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);

  /// A sequência em [now] com os dias de atividade [days].
  static Streak of(Set<DateTime> days, DateTime now) {
    final active = {for (final at in days) day(at)};
    final today = day(now);
    final yesterday = _before(today);
    final activeToday = active.contains(today);
    final current = _runEndingAt(active, activeToday ? today : yesterday);
    // Ontem sem nada: a sequência que terminava antes de ontem acabou.
    final lost = activeToday || active.contains(yesterday)
        ? 0
        : _runEndingAt(active, _before(yesterday));
    var record = current;
    for (final start in active) {
      // Só conta a partir do primeiro dia de cada sequência.
      if (active.contains(_before(start))) continue;
      var length = 0;
      for (var d = start; active.contains(d); d = _next(d)) {
        length++;
      }
      if (length > record) record = length;
    }
    return Streak(
      current: current,
      record: record,
      activeToday: activeToday,
      lost: lost,
    );
  }

  /// O último dia da sequência que acabou em [now] (anteontem), se
  /// `Streak.lost` não é zero.
  static DateTime lostLastDay(DateTime now) => _before(_before(day(now)));

  /// Os dias da sequência atual em [now], do mais recente ao mais antigo.
  static List<DateTime> run(Set<DateTime> days, DateTime now) {
    final active = {for (final at in days) day(at)};
    final today = day(now);
    return [
      for (
        var d = active.contains(today) ? today : _before(today);
        active.contains(d);
        d = _before(d)
      )
        d,
    ];
  }

  /// Os 7 dias da semana de [now], de segunda a domingo.
  static List<DateTime> week(DateTime now) {
    final today = day(now);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday),
    );
    return [
      for (var i = 0; i < DateTime.daysPerWeek; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];
  }

  /// Os dias do mês de [now], do 1º ao último.
  static List<DateTime> month(DateTime now) {
    final today = day(now);
    final last = DateTime(today.year, today.month + 1, 0).day;
    return [
      for (var d = 1; d <= last; d++) DateTime(today.year, today.month, d),
    ];
  }

  static DateTime _next(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);

  static int _runEndingAt(Set<DateTime> active, DateTime end) {
    var length = 0;
    for (var d = end; active.contains(d); d = _before(d)) {
      length++;
    }
    return length;
  }
}
