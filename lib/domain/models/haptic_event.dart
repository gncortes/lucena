/// O retorno tátil de cada momento do app (T51, G4).
enum HapticEvent {
  /// Pegar uma peça, tocar numa casa, trocar uma opção.
  selection,

  /// Lance do jogador aceito.
  move,

  /// Captura do jogador.
  capture,

  /// Xeque do jogador.
  check,

  /// Vitória, exercício resolvido, parte da aula concluída.
  success,

  /// Conquista nova, recorde, diploma.
  celebrate,

  /// Pouco tempo no relógio (uma vez por partida).
  warning,
}
