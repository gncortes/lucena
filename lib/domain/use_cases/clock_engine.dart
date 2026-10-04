import 'package:dartchess/dartchess.dart';

import '../models/clock.dart';

/// Regras do relógio de xadrez. Não conta tiques: toda conta parte do
/// instante em que a vez começou, recebido de fora (`Now`).
abstract final class ClockEngine {
  /// Abaixo disso o tempo é "pouco": aparecem os décimos e o aparelho vibra.
  static const lowTime = Duration(seconds: 10);

  /// O relógio no começo da partida, já correndo para quem joga.
  static ClockState start(
    ClockConfig config, {
    required Side turn,
    required DateTime now,
  }) {
    return ClockState(
      config: config,
      white: config.white.initial,
      black: config.black.initial,
      running: turn,
      turnStartedAt: now,
    );
  }

  /// Quanto falta para [side] no instante [now]. Nunca menos que zero.
  static Duration remaining(ClockState clock, Side side, DateTime now) {
    final atTurnStart = clock.of(side);
    final startedAt = clock.turnStartedAt;
    if (clock.running != side || startedAt == null) return atTurnStart;
    final elapsed = now.difference(startedAt);
    // Relógio do aparelho atrasado pelo usuário: não devolve tempo.
    if (elapsed.isNegative) return atTurnStart;
    final left = atTurnStart - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  /// O lado cujo tempo acabou, se acabou.
  static Side? flagged(ClockState clock, DateTime now) {
    final running = clock.running;
    if (running == null) return null;
    return remaining(clock, running, now) == Duration.zero ? running : null;
  }

  /// Quem estava na vez jogou: desconta o tempo gasto, soma o incremento e
  /// passa o relógio para o outro lado.
  static ClockState press(ClockState clock, DateTime now) {
    final side = clock.running;
    if (side == null) return clock;
    final left = remaining(clock, side, now) + clock.config.of(side).increment;
    return _withTime(
      clock,
      side,
      left,
    ).copyWith(running: side.opposite, turnStartedAt: now);
  }

  /// Para o relógio (fim de partida ou pausa), guardando quanto cada lado tem.
  static ClockState stop(ClockState clock, DateTime now) {
    final side = clock.running;
    if (side == null) return clock;
    return _withTime(
      clock,
      side,
      remaining(clock, side, now),
    ).copyWith(running: null, turnStartedAt: null);
  }

  /// Volta a correr para [turn], a partir de [now].
  static ClockState resume(
    ClockState clock, {
    required Side turn,
    required DateTime now,
  }) {
    if (clock.running != null) return clock;
    return clock.copyWith(running: turn, turnStartedAt: now);
  }

  static ClockState _withTime(ClockState clock, Side side, Duration time) =>
      side == Side.white
      ? clock.copyWith(white: time)
      : clock.copyWith(black: time);
}
