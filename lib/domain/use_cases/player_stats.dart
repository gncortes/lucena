import '../models/attempt.dart';

/// Os números do jogador na tela inicial: partidas, vitórias e a sequência de
/// dias seguidos com partida.
class PlayerStats {
  const PlayerStats({
    required this.games,
    required this.wins,
    required this.streakDays,
  });

  /// Conta as partidas de [attempts] até [now]. A sequência vale até hoje ou
  /// ontem (quem ainda não jogou hoje não perde a sequência de manhã).
  factory PlayerStats.of(List<Attempt> attempts, DateTime now) {
    final days = {for (final attempt in attempts) _day(attempt.playedAt)};
    var day = _day(now);
    if (!days.contains(day)) day = day.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = _day(day.subtract(const Duration(hours: 12)));
    }
    return PlayerStats(
      games: attempts.length,
      wins: attempts
          .where((attempt) => attempt.outcome == AttemptOutcome.win)
          .length,
      streakDays: streak,
    );
  }

  final int games;
  final int wins;
  final int streakDays;

  // O dia no fuso do aparelho, à meia-noite.
  static DateTime _day(DateTime at) {
    final local = at.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
}
