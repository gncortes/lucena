/// O rating do jogador no Glicko-2: o valor, a incerteza (desvio) e a
/// volatilidade.
class PlayerRating {
  const PlayerRating({
    required this.rating,
    this.deviation = initialDeviation,
    this.volatility = initialVolatility,
  });

  /// O começo: o rating escolhido no perfil, com a incerteza máxima.
  factory PlayerRating.start(int rating) =>
      PlayerRating(rating: rating.toDouble());

  /// Desvio de quem ainda não jogou (e o teto do Glicko-2). No Lucena, a
  /// partida usa no máximo `RatingRules.maxDeviation`.
  static const initialDeviation = 350.0;

  /// Volatilidade inicial do Glicko-2.
  static const initialVolatility = 0.06;

  final double rating;
  final double deviation;
  final double volatility;

  /// O rating mostrado na tela.
  int get rounded => rating.round();

  @override
  bool operator ==(Object other) =>
      other is PlayerRating &&
      other.rating == rating &&
      other.deviation == deviation &&
      other.volatility == volatility;

  @override
  int get hashCode => Object.hash(rating, deviation, volatility);

  @override
  String toString() => 'PlayerRating($rating, $deviation, $volatility)';
}

/// Um ponto do histórico do rating: como ficou depois de uma partida ou de
/// um bônus de speedrun.
class RatingEntry {
  const RatingEntry({
    required this.rating,
    required this.at,
    this.gameId,
    this.speedrunAttemptId,
  });

  final PlayerRating rating;
  final DateTime at;

  /// A partida que deu este rating. Nulo no ponto inicial e no bônus.
  final int? gameId;

  /// A tentativa de speedrun cuja conclusão deu este bônus. Nulo nas
  /// partidas.
  final int? speedrunAttemptId;

  /// O ponto é um bônus de speedrun, não uma partida.
  bool get isBonus => speedrunAttemptId != null;

  @override
  bool operator ==(Object other) =>
      other is RatingEntry &&
      other.rating == rating &&
      other.at == at &&
      other.gameId == gameId &&
      other.speedrunAttemptId == speedrunAttemptId;

  @override
  int get hashCode => Object.hash(rating, at, gameId, speedrunAttemptId);
}

/// O bônus de rating pago pela conclusão de uma tentativa de speedrun.
class SpeedrunBonus {
  const SpeedrunBonus({
    required this.attemptId,
    required this.speedrunId,
    required this.before,
    required this.after,
    required this.at,
  });

  final int attemptId;

  /// O speedrun da tentativa, com o ritmo (`ending.rook@600+0`).
  final String speedrunId;

  /// O rating antes e depois do bônus.
  final PlayerRating before;
  final PlayerRating after;
  final DateTime at;

  /// Os pontos ganhos, como a tela mostra.
  int get points => after.rounded - before.rounded;

  @override
  bool operator ==(Object other) =>
      other is SpeedrunBonus &&
      other.attemptId == attemptId &&
      other.speedrunId == speedrunId &&
      other.before == before &&
      other.after == after &&
      other.at == at;

  @override
  int get hashCode => Object.hash(attemptId, speedrunId, before, after, at);
}
