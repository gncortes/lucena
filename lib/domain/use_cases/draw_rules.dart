/// Quando a máquina aceita o empate proposto pelo jogador: só quando ela está
/// bem pior. Contra uma pessoa de verdade é igual: ninguém aceita empate na
/// posição boa.
abstract final class DrawRules {
  /// O Maia aceita quando a própria previsão dele (pessoas do nível dele
  /// naquela posição) dá a ele no máximo esta chance de pontos.
  static const maiaMaxExpected = 0.25;

  /// O Stockfish aceita quando a avaliação dele está pelo menos tanto contra
  /// ele (em centipeões; mate contra ele também).
  static const engineMinDeficit = 400;

  /// Depois de uma recusa, quantos lances (dos dois lados) até poder propor
  /// de novo.
  static const cooldownPlies = 6;

  /// [win], [draw] e [loss] são a previsão para a máquina.
  static bool maiaAccepts({required double win, required double draw}) =>
      win + draw / 2 <= maiaMaxExpected;

  /// [score] é a avaliação do ponto de vista da máquina.
  static bool engineAccepts(int score) => score <= -engineMinDeficit;
}
