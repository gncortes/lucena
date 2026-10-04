/// Desenhos das peças como caracteres de texto, na fonte de figurinos do app
/// (recorte da Noto Sans Symbols 2, ver `tools/make_figurine_font.py`): têm a
/// cor e a linha de base do texto em volta.
abstract final class Figurine {
  static const fontFamily = 'LucenaFigurine';

  /// Letra da peça na notação algébrica e o desenho vazado dela.
  static const ofLetter = {'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘'};
}
