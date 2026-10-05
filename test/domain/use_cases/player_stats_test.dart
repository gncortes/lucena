import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/player_stats.dart';

void main() {
  final now = DateTime(2026, 10, 5, 15);

  Attempt game(DateTime at, {bool won = true}) => Attempt(
    positionId: 'basic.queen.0001',
    playedAt: at,
    outcome: won ? AttemptOutcome.win : AttemptOutcome.loss,
    fulfilled: won,
    opponent: OpponentKind.maia,
  );

  test('sem partidas, tudo zero', () {
    final stats = PlayerStats.of(const [], now);
    expect(stats.games, 0);
    expect(stats.wins, 0);
    expect(stats.streakDays, 0);
  });

  test('conta partidas e vitórias', () {
    final stats = PlayerStats.of([
      game(now),
      game(now, won: false),
      game(now),
    ], now);
    expect(stats.games, 3);
    expect(stats.wins, 2);
  });

  test('a sequência conta os dias seguidos até hoje', () {
    final stats = PlayerStats.of([
      game(DateTime(2026, 10, 5, 9)),
      game(DateTime(2026, 10, 4, 22)),
      game(DateTime(2026, 10, 3, 8)),
      // Um buraco no dia 2: o dia 1 não conta.
      game(DateTime(2026, 10, 1, 8)),
    ], now);
    expect(stats.streakDays, 3);
  });

  test('quem ainda não jogou hoje mantém a sequência de ontem', () {
    final stats = PlayerStats.of([
      game(DateTime(2026, 10, 4, 22)),
      game(DateTime(2026, 10, 3, 8)),
    ], now);
    expect(stats.streakDays, 2);
  });

  test('dois dias sem jogar: a sequência zera', () {
    final stats = PlayerStats.of([game(DateTime(2026, 10, 3, 8))], now);
    expect(stats.streakDays, 0);
  });
}
