import 'package:freezed_annotation/freezed_annotation.dart';

import 'clock.dart';
import 'speedrun_pace.dart';

part 'clock_settings.freezed.dart';

/// Onde os relógios aparecem na tela da partida.
enum ClockPosition {
  /// Cada relógio do seu lado do tabuleiro: um em cima, outro embaixo.
  sides,

  /// Os dois juntos, acima do tabuleiro.
  top,

  /// Os dois juntos, abaixo do tabuleiro.
  bottom;

  static const fallback = ClockPosition.sides;

  /// Valor gravado nas preferências.
  String get code => name;

  static ClockPosition fromCode(String? code) =>
      values.asNameMap()[code] ?? fallback;
}

/// Preferências do relógio.
@freezed
abstract class ClockSettings with _$ClockSettings {
  const factory ClockSettings({
    @Default(ClockPosition.fallback) ClockPosition position,

    /// Vibra uma vez quando o tempo de quem joga fica abaixo de 10 s.
    @Default(true) bool lowTimeVibration,

    /// O último ritmo escolhido para um speedrun.
    @Default(SpeedrunPaces.standard) TimeControl speedrunTime,

    /// O último ritmo escolhido para um desafio da Jornada. Nulo: sem relógio.
    TimeControl? journeyTime,
  }) = _ClockSettings;
}
