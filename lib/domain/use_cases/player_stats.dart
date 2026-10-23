import '../models/attempt.dart';

/// Os números do jogador: partidas e vitórias. A sequência de dias fica com
/// `StreakRules`, que conta também aulas e finais.
class PlayerStats {
  const PlayerStats({required this.games, required this.wins});

  factory PlayerStats.of(List<Attempt> attempts) => PlayerStats(
    games: attempts.length,
    wins: attempts
        .where((attempt) => attempt.outcome == AttemptOutcome.win)
        .length,
  );

  final int games;
  final int wins;
}
