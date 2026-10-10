/// O cronômetro de um passo de exercício (T60): o tempo decorrido desde que o
/// passo abriu, em tempo de relógio de parede. Sair do app e voltar continua
/// a contagem de onde estava, porque o começo fica gravado no checkpoint.
abstract final class StepClock {
  /// Quanto tempo passou desde [startedAt] até [now]. Nunca negativo: se o
  /// relógio do aparelho voltou (fuso, hora mudada à mão), conta do zero.
  static Duration elapsed({
    required DateTime startedAt,
    required DateTime now,
  }) {
    final elapsed = now.difference(startedAt);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  /// O tempo como no cronômetro: `m:ss` e, de uma hora em diante, `h:mm:ss`.
  /// Só segundos inteiros, arredondados para baixo.
  static String format(Duration elapsed) {
    final total = elapsed.isNegative ? 0 : elapsed.inSeconds;
    final seconds = (total % 60).toString().padLeft(2, '0');
    final minutes = (total ~/ 60) % 60;
    final hours = total ~/ 3600;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds';
  }
}
