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
    final stats = PlayerStats.of(const []);
    expect(stats.games, 0);
    expect(stats.wins, 0);
  });

  test('conta partidas e vitórias', () {
    final stats = PlayerStats.of([game(now), game(now, won: false), game(now)]);
    expect(stats.games, 3);
    expect(stats.wins, 2);
  });
}
