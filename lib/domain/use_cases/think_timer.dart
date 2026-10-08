/// O tempo de pensar de um passo `think` (T51, C1). É tempo de relógio de
/// parede: se o aluno sai do app e volta, o tempo continua contado desde o
/// começo.
sealed class ThinkPhase {
  const ThinkPhase();
}

/// Ainda pensando: falta [remaining].
class Thinking extends ThinkPhase {
  const Thinking(this.remaining);

  final Duration remaining;

  @override
  bool operator ==(Object other) =>
      other is Thinking && other.remaining == remaining;

  @override
  int get hashCode => remaining.hashCode;
}

/// O tempo acabou: vêm as dicas e "Ver explicação".
class ThinkExpired extends ThinkPhase {
  const ThinkExpired();

  @override
  bool operator ==(Object other) => other is ThinkExpired;

  @override
  int get hashCode => 0;
}

abstract final class ThinkTimer {
  /// A fase de quem começou a pensar em [startedAt], com [time] para pensar,
  /// no instante [now].
  static ThinkPhase phase({
    required DateTime startedAt,
    required Duration time,
    required DateTime now,
  }) {
    final remaining = time - now.difference(startedAt);
    if (remaining <= Duration.zero) return const ThinkExpired();
    // Relógio voltou (fuso, hora mudada à mão): no máximo o tempo todo.
    return Thinking(remaining > time ? time : remaining);
  }
}
