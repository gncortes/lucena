import '../models/player_rating.dart';

/// Os períodos do gráfico do rating, como no chess.com: os últimos 7, 30 e 90
/// dias, o último ano ou tudo.
enum RatingPeriod {
  week(7),
  month(30),
  quarter(90),
  year(365),
  all(null);

  const RatingPeriod(this.days);

  /// Quantos dias para trás. Nulo: desde a primeira partida.
  final int? days;

  /// Os pontos do [history] (do mais antigo para o mais recente) dentro do
  /// período que termina em [now]. Quando há um ponto anterior ao período,
  /// ele vem primeiro: é de onde o rating partiu.
  List<RatingEntry> entries(List<RatingEntry> history, DateTime now) {
    final days = this.days;
    if (days == null) return history;
    final start = now.subtract(Duration(days: days));
    final first = history.indexWhere((entry) => !entry.at.isBefore(start));
    if (first == -1) return const [];
    return history.sublist(first > 0 ? first - 1 : 0);
  }

  /// Quanto o rating mudou no período. Nulo sem dois pontos para comparar.
  int? change(List<RatingEntry> history, DateTime now) {
    final entries = this.entries(history, now);
    if (entries.length < 2) return null;
    return entries.last.rating.rounded - entries.first.rating.rounded;
  }
}

/// O ponto mais alto do rating. Nulo sem histórico.
RatingEntry? highestRating(List<RatingEntry> history) {
  RatingEntry? best;
  for (final entry in history) {
    if (best == null || entry.rating.rating > best.rating.rating) best = entry;
  }
  return best;
}
