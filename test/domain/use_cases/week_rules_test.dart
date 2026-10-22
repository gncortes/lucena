import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/daily_final.dart';
import 'package:lucena/domain/use_cases/week_rules.dart';

void main() {
  // Quinta, 22 de outubro de 2026: a semana vai de 19 a 25.
  final now = DateTime(2026, 10, 22, 9);

  DailyRecord daily(int day, List<DailySquare> squares) => DailyRecord(
    date: DateTime(2026, 10, day),
    positionId: 'p$day',
    outcome: DailyOutcome.values.first,
    fulfilled: true,
    squares: squares,
  );

  test('conta as partidas da semana por dia e os lances de primeira', () {
    final week = WeekRules.of(
      now: now,
      played: [
        DateTime(2026, 10, 18, 22), // domingo passado: fora
        DateTime(2026, 10, 19, 8),
        DateTime(2026, 10, 21, 10),
        DateTime(2026, 10, 21, 23, 59),
        DateTime(2026, 10, 22, 7),
      ],
      daily: [
        daily(18, [DailySquare.right, DailySquare.right]),
        daily(19, [DailySquare.right, DailySquare.bad, DailySquare.right]),
        daily(21, [DailySquare.right, DailySquare.slow]),
      ],
      ratingFrom: 1152,
      ratingTo: 1192,
      streakDays: 4,
    );

    expect(week.monday, DateTime(2026, 10, 19));
    expect(week.sunday, DateTime(2026, 10, 25));
    expect(week.perDay, [1, 0, 2, 1, 0, 0, 0]);
    expect(week.finals, 4);
    expect(week.firstTry, 3);
    expect(week.points, 40);
    expect(week.bestDay, DateTime(2026, 10, 21));
  });

  test('sem partidas, sem melhor dia; empate fica com o primeiro', () {
    final empty = WeekRules.of(
      now: now,
      played: const [],
      daily: const [],
      ratingFrom: 1200,
      ratingTo: 1188,
      streakDays: 0,
    );
    expect(empty.finals, 0);
    expect(empty.bestDay, isNull);
    expect(empty.points, -12);

    final tie = WeekRules.of(
      now: now,
      played: [DateTime(2026, 10, 20, 9), DateTime(2026, 10, 22, 8)],
      daily: const [],
      ratingFrom: 1200,
      ratingTo: 1200,
      streakDays: 0,
    );
    expect(tie.bestDay, DateTime(2026, 10, 20));
  });
}
