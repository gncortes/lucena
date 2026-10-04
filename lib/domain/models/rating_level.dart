/// Faixas de rating que o jogador escolhe no perfil, da mais fraca à mais forte.
enum RatingLevel {
  beginner(max: 999, rating: 800),
  casual(min: 1000, max: 1299, rating: 1150),
  intermediate(min: 1300, max: 1599, rating: 1450),
  advanced(min: 1600, max: 1899, rating: 1750),
  expert(min: 1900, max: 2199, rating: 2050),
  master(min: 2200, rating: 2400);

  const RatingLevel({required this.rating, this.min, this.max});

  /// Menor rating da faixa. Nulo na primeira, que não tem piso.
  final int? min;

  /// Maior rating da faixa. Nulo na última, que não tem teto.
  final int? max;

  /// O rating gravado para quem escolhe esta faixa (perto do meio dela).
  final int rating;

  /// A faixa em que um rating cai.
  static RatingLevel of(int rating) {
    for (final level in values) {
      final max = level.max;
      if (max == null || rating <= max) return level;
    }
    return master;
  }
}
