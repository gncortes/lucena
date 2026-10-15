/// O resultado de uma posição com o melhor jogo, do ponto de vista de quem
/// joga nela (T76).
enum Wdl {
  win,
  draw,
  loss;

  /// O mesmo resultado visto pelo outro lado.
  Wdl get flipped => switch (this) {
    win => loss,
    draw => draw,
    loss => win,
  };

  /// A letra do asset da tabela do roteiro (`w`, `d`, `l`).
  static Wdl? parse(String letter) => switch (letter) {
    'w' => win,
    'd' => draw,
    'l' => loss,
    _ => null,
  };
}
