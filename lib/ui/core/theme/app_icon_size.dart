/// A escala de tamanhos de ícone do app (D34): 16, 20, 24, 32, 48. Ícone sem
/// `size:` já é [standard].
abstract final class AppIconSize {
  /// Dentro de chip e de selo.
  static const small = 16.0;

  /// Dentro de botão e de aviso.
  static const button = 20.0;

  /// O padrão do Material.
  static const standard = 24.0;

  /// Destaque numa linha ou num cartão.
  static const large = 32.0;

  /// Ilustração de estado vazio e de erro.
  static const illustration = 48.0;
}
