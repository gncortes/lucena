import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/streak_rules.dart';

void main() {
  Set<DateTime> days(List<int> octoberDays) => {
    for (final d in octoberDays) DateTime(2026, 10, d, 15),
  };
  final now = DateTime(2026, 10, 22, 9);

  test('conta até hoje, com atividade hoje', () {
    final streak = StreakRules.of(days([20, 21, 22]), now);
    expect(streak.current, 3);
    expect(streak.activeToday, isTrue);
    expect(streak.lost, 0);
  });

  test('de manhã, sem nada hoje, a sequência de ontem continua', () {
    final streak = StreakRules.of(days([20, 21]), now);
    expect(streak.current, 2);
    expect(streak.activeToday, isFalse);
    expect(streak.lost, 0);
  });

  test('ontem sem nada: volta a zero e diz quantos dias acabaram', () {
    final streak = StreakRules.of(days([18, 19, 20]), now);
    expect(streak.current, 0);
    expect(streak.lost, 3);
    expect(streak.record, 3);
  });

  test('o recorde fica com a maior sequência', () {
    final streak = StreakRules.of(days([1, 2, 3, 4, 5, 10, 21, 22]), now);
    expect(streak.current, 2);
    expect(streak.record, 5);
    expect(streak.toRecord, 3);
  });

  test('sem dias, nada', () {
    final streak = StreakRules.of({}, now);
    expect(streak.current, 0);
    expect(streak.record, 0);
    expect(streak.lost, 0);
  });

  test('vira o mês sem quebrar', () {
    final streak = StreakRules.of({
      DateTime(2026, 9, 29),
      DateTime(2026, 9, 30),
      DateTime(2026, 10, 1, 23, 59),
    }, DateTime(2026, 10, 1, 23, 59));
    expect(streak.current, 3);
  });

  test('o horário de verão não pula nem repete dia', () {
    // Dias de 23 e 25 horas: as contas andam por data.
    final streak = StreakRules.of({
      for (var d = 1; d <= 10; d++) DateTime(2026, 3, 25 + d),
    }, DateTime(2026, 4, 4, 12));
    expect(streak.current, 10);
  });

  test('a semana vai de segunda a domingo', () {
    // 22/10/2026 é quinta-feira.
    final week = StreakRules.week(now);
    expect(week.first, DateTime(2026, 10, 19));
    expect(week.last, DateTime(2026, 10, 25));
    expect(week, hasLength(7));
  });

  test('o mês tem todos os dias', () {
    expect(StreakRules.month(now), hasLength(31));
    expect(StreakRules.month(DateTime(2026, 2, 3)), hasLength(28));
  });

  test('os dias da sequência atual, sem os de antes do buraco', () {
    expect(StreakRules.run(days([10, 20, 21]), now), [
      DateTime(2026, 10, 21),
      DateTime(2026, 10, 20),
    ]);
  });
}
