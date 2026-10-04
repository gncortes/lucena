/// Quanto a máquina pensa em cada lance, a partir do relógio dela.
abstract final class ThinkTimePolicy {
  /// Sem relógio, a máquina pensa sempre isto.
  static const untimed = Duration(seconds: 1);

  /// Teto: nos finais de treino, mais tempo não muda o lance e só faz o
  /// jogador esperar.
  static const max = Duration(seconds: 2);

  /// Piso: o motor precisa de um instante para responder.
  static const min = Duration(milliseconds: 50);

  /// Uma fatia do tempo que resta mais quase todo o incremento, entre [min] e
  /// [max]. Nunca passa de um quarto do que resta: com pouco tempo, a máquina
  /// joga rápido e não perde por tempo.
  static Duration of({
    Duration? remaining,
    Duration increment = Duration.zero,
  }) {
    if (remaining == null) return untimed;
    if (remaining <= Duration.zero) return Duration.zero;
    var think = remaining ~/ 30 + increment * 3 ~/ 4;
    if (think > max) think = max;
    if (think < min) think = min;
    final safe = remaining ~/ 4;
    return think > safe ? safe : think;
  }
}
