/// O que o Maia prevê para uma posição num nível.
class MovePrediction {
  const MovePrediction({
    required this.moves,
    required this.win,
    required this.draw,
    required this.loss,
    required this.elapsed,
  });

  /// A chance de uma pessoa daquele nível fazer cada lance legal (UCI), do
  /// mais provável para o menos. Soma 1; vazio se não há lance.
  final Map<String, double> moves;

  /// Chance de quem joga ganhar, empatar e perder a partida.
  final double win;
  final double draw;
  final double loss;

  /// Quanto o modelo levou para calcular.
  final Duration elapsed;
}
