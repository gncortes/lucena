/// Os raios de borda do app (T51, G3): quatro valores, nada escrito à mão. O
/// teste `test/ui/core/motion_usage_test.dart` acusa raio com número fora
/// destes.
abstract final class AppShape {
  /// Chips, caixas do relógio, barras finas, cantos do tabuleiro.
  static const small = 8.0;

  /// Botões, campos.
  static const medium = 12.0;

  /// Cartões, painéis, balões.
  static const large = 16.0;

  /// Pílulas e retratos redondos: maior que qualquer meia altura.
  static const full = 999.0;
}
