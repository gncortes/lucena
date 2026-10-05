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

  /// Desvio de quem ainda não jogou (e o teto do desvio).
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

/// Um ponto do histórico do rating: como ficou depois de uma partida.
class RatingEntry {
  const RatingEntry({required this.rating, required this.at, this.gameId});

  final PlayerRating rating;
  final DateTime at;

  /// A partida que deu este rating. Nulo no ponto inicial.
  final int? gameId;

  @override
  bool operator ==(Object other) =>
      other is RatingEntry &&
      other.rating == rating &&
      other.at == at &&
      other.gameId == gameId;

  @override
  int get hashCode => Object.hash(rating, at, gameId);
}
