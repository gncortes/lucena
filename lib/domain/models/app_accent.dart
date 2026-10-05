/// Cor predominante do app: botões, destaques e o tom do fundo.
enum AppAccent {
  blue,
  green,
  purple,
  pink,
  orange,
  teal;

  /// Valor gravado nas preferências.
  String get code => name;

  /// Código desconhecido ou ausente: nenhuma cor escolhida.
  static AppAccent? fromCode(String? code) => values.asNameMap()[code];

  /// A cor de fábrica de cada tema: azul no claro, verde no escuro.
  static AppAccent standard({required bool dark}) => dark ? green : blue;
}
