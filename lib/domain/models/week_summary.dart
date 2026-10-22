/// O resumo de uma semana, de segunda a domingo (E1.23): a tela "Sua semana"
/// e a notificação de domingo.
class WeekSummary {
  const WeekSummary({
    required this.monday,
    required this.finals,
    required this.perDay,
    required this.ratingFrom,
    required this.ratingTo,
    required this.streakDays,
    required this.firstTry,
  });

  /// A segunda-feira da semana, à meia-noite local.
  final DateTime monday;

  /// As partidas de final concluídas na semana (do dia, de torneio, treinar).
  final int finals;

  /// As partidas de cada dia, de segunda (0) a domingo (6).
  final List<int> perDay;

  /// O rating no começo da semana e agora, arredondados.
  final int ratingFrom;
  final int ratingTo;

  /// A sequência de dias agora.
  final int streakDays;

  /// Os lances certos de primeira (os quadradinhos verdes dos finais do dia
  /// da semana).
  final int firstTry;

  DateTime get sunday => DateTime(monday.year, monday.month, monday.day + 6);

  /// Quanto o rating subiu (negativo: caiu).
  int get points => ratingTo - ratingFrom;

  /// O dia com mais partidas (o primeiro, no empate). Nulo sem partida.
  DateTime? get bestDay {
    var best = -1;
    for (var i = 0; i < perDay.length; i++) {
      if (perDay[i] > 0 && (best < 0 || perDay[i] > perDay[best])) best = i;
    }
    return best < 0
        ? null
        : DateTime(monday.year, monday.month, monday.day + best);
  }
}
