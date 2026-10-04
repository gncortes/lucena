/// Quanto a máquina pensa em cada lance, a partir do relógio dela.
abstract final class ThinkTimePolicy {
  /// Sem relógio, a máquina pensa sempre isto.
  static const untimed = Duration(seconds: 1);

  /// Teto: nos finais de treino, mais tempo não muda o lance e só faz o
  /// jogador esperar.
  static const max = Duration(seconds: 2);

  /// Piso: o motor precisa de um instante para responder.
  static const min = Duration(milliseconds: 50);

  /// Abaixo disto no relógio, a máquina está apurada e joga rápido.
  static const lowTime = Duration(seconds: 10);

  /// O máximo que ela pensa quando está apurada, mesmo com incremento.
  static const lowTimeMax = Duration(milliseconds: 500);

  /// A partir desta probabilidade, o lance é óbvio (uma recaptura, o único
  /// lance bom) e sai quase na hora.
  static const obvious = 0.85;

  /// Quanto leva um lance óbvio.
  static const instant = Duration(milliseconds: 300);

  /// O tempo de que a máquina dispõe para um lance: uma fatia do tempo que
  /// resta mais quase todo o incremento, entre [min] e [max]. Nunca passa de
  /// um quarto do que resta: com pouco tempo, a máquina joga rápido e não
  /// perde por tempo.
  static Duration of({
    Duration? remaining,
    Duration increment = Duration.zero,
  }) {
    if (remaining == null) return untimed;
    if (remaining <= Duration.zero) return Duration.zero;
    var think = remaining ~/ 30 + increment * 3 ~/ 4;
    if (think > max) think = max;
    if (remaining < lowTime && think > lowTimeMax) think = lowTimeMax;
    if (think < min) think = min;
    final safe = remaining ~/ 4;
    return think > safe ? safe : think;
  }

  /// Quanto um adversário humano (o Maia) pensa num lance, dentro do tempo
  /// [budget] que [of] deu. [certainty] é a probabilidade do lance escolhido:
  /// lance óbvio sai quase na hora; quanto mais dúvida, mais perto do tempo
  /// todo. [roll] (de 0 a 1) varia o tempo de um lance para o outro.
  ///
  /// Nunca passa de [budget]: a garantia de não perder por tempo continua.
  static Duration human({
    required Duration budget,
    required double certainty,
    required double roll,
  }) {
    if (budget <= Duration.zero) return Duration.zero;
    final jitter = 0.7 + 0.6 * roll.clamp(0.0, 1.0);
    final Duration think;
    if (certainty >= obvious) {
      think = instant * jitter;
    } else {
      final doubt = 1 - certainty.clamp(0.0, obvious) / obvious;
      think = budget * ((0.35 + 0.65 * doubt) * jitter);
    }
    return think > budget ? budget : think;
  }
}
