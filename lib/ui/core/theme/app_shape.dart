/// Os raios de borda do app (T51, G3): valores compartilhados, nada escrito à mão. O
/// teste `test/ui/core/motion_usage_test.dart` acusa raio com número fora
/// destes.
abstract final class AppShape {
  /// Cantos retos: o tabuleiro de jogar, sem moldura.
  static const none = 0.0;

  /// Barra de rolagem fina e alça do painel (LICOES-V2 §5, A10).
  static const hairline = 2.0;

  /// Destaque do lance no texto (LICOES-V2 §2, A5).
  static const tiny = 4.0;

  /// Chips, caixas do relógio, barras finas, cantos do tabuleiro.
  static const small = 8.0;

  /// Botões, campos.
  static const medium = 12.0;

  /// Cartões, painéis, balões.
  static const large = 16.0;

  /// Cards that use the 20 dp panel radius in the T85 Canvas.
  static const card = 20.0;

  /// Diálogos e folhas da proposta V2.
  static const extraLarge = 28.0;

  /// Pílulas e retratos redondos: maior que qualquer meia altura.
  static const full = 999.0;
}
