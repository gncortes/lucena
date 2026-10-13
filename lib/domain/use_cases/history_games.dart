import '../models/attempt.dart';
import '../models/history_filter.dart';
import '../models/player_rating.dart';

/// Uma partida que contou para o rating, como a aba Partidas a mostra.
class HistoryGame {
  const HistoryGame({
    required this.id,
    required this.attempt,
    required this.entry,
    this.change,
    this.accuracy,
  });

  /// O id da partida gravada: abre os detalhes dela.
  final int id;
  final Attempt attempt;

  /// O ponto do rating logo depois dela.
  final RatingEntry entry;

  /// Quanto ela mudou o rating (contando um bônus anterior). Nulo na
  /// primeira.
  final int? change;

  /// A precisão do jogador, se a partida já foi revisada.
  final double? accuracy;
}

/// Vitórias, empates e derrotas de uma lista de partidas.
class GamesScore {
  const GamesScore({this.wins = 0, this.draws = 0, this.losses = 0});

  final int wins;
  final int draws;
  final int losses;

  int get total => wins + draws + losses;
}

/// As contas da aba Partidas do Histórico.
abstract final class HistoryGames {
  /// As partidas do [history] (do mais antigo para o mais recente), da mais
  /// recente para a mais antiga. Ficam de fora os bônus, as etapas de
  /// speedrun e o que não tem partida gravada em [attempts].
  static List<HistoryGame> build(
    List<RatingEntry> history, {
    required Map<int, Attempt> attempts,
    Map<int, double> accuracies = const {},
  }) => [
    for (var index = history.length - 1; index >= 0; index--)
      if (_game(history[index], attempts) case final attempt?)
        HistoryGame(
          id: history[index].gameId!,
          attempt: attempt,
          entry: history[index],
          change: index == 0
              ? null
              : history[index].rating.rounded -
                    history[index - 1].rating.rounded,
          accuracy: accuracies[history[index].gameId],
        ),
  ];

  static Attempt? _game(RatingEntry entry, Map<int, Attempt> attempts) {
    final id = entry.gameId;
    if (entry.isBonus || id == null) return null;
    final attempt = attempts[id];
    return attempt == null || attempt.speedrunAttemptId != null
        ? null
        : attempt;
  }

  /// Quantas entradas do [history] são partidas que contaram (sem bônus).
  static int counted(List<RatingEntry> history) =>
      history.where((entry) => !entry.isBonus).length;

  /// As partidas de [games] que passam por [filter], em relação a [now].
  static List<HistoryGame> filter(
    List<HistoryGame> games,
    GamesHistoryFilter filter,
    DateTime now,
  ) {
    final days = filter.period.days;
    final start = days == null ? null : now.subtract(Duration(days: days));
    return [
      for (final game in games)
        if ((start == null || !game.entry.at.isBefore(start)) &&
            (filter.result == null || game.attempt.outcome == filter.result) &&
            filter.matchesPace(game.attempt.userTime))
          game,
    ];
  }

  /// O placar de [games].
  static GamesScore score(Iterable<HistoryGame> games) {
    var wins = 0, draws = 0, losses = 0;
    for (final game in games) {
      switch (game.attempt.outcome) {
        case AttemptOutcome.win:
          wins++;
        case AttemptOutcome.draw:
          draws++;
        case AttemptOutcome.loss:
          losses++;
      }
    }
    return GamesScore(wins: wins, draws: draws, losses: losses);
  }
}
