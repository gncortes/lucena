import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'clock.freezed.dart';

/// Tempo de um lado: o que ele tem no começo e o que ganha a cada lance.
@freezed
abstract class TimeControl with _$TimeControl {
  const factory TimeControl({
    required Duration initial,
    @Default(Duration.zero) Duration increment,
  }) = _TimeControl;

  const TimeControl._();

  /// Lê `segundos+incremento` (`300+2`). Nulo se o texto não for isso ou se o
  /// tempo inicial for zero.
  static TimeControl? tryParse(String? code) {
    final match = RegExp(r'^(\d+)\+(\d+)$').firstMatch(code ?? '');
    if (match == null) return null;
    final initial = Duration(seconds: int.parse(match.group(1)!));
    if (initial == Duration.zero) return null;
    return TimeControl(
      initial: initial,
      increment: Duration(seconds: int.parse(match.group(2)!)),
    );
  }

  /// `segundos+incremento`, o formato lido por [tryParse].
  String get code => '${initial.inSeconds}+${increment.inSeconds}';
}

/// O tempo de cada lado numa partida. Podem ser diferentes.
@freezed
abstract class ClockConfig with _$ClockConfig {
  const factory ClockConfig({
    required TimeControl white,
    required TimeControl black,
  }) = _ClockConfig;

  /// O mesmo tempo para os dois lados.
  factory ClockConfig.same(TimeControl time) =>
      ClockConfig(white: time, black: time);

  const ClockConfig._();

  TimeControl of(Side side) => side == Side.white ? white : black;
}

/// O relógio de uma partida, guardado em instantes: quanto cada lado tinha
/// quando a vez atual começou e em que instante ela começou. Quanto falta
/// agora sai da conta, sem depender de o app estar aberto.
@freezed
abstract class ClockState with _$ClockState {
  const factory ClockState({
    required ClockConfig config,

    /// Quanto as brancas tinham no começo da vez atual (ou ao parar).
    required Duration white,

    /// Quanto as pretas tinham no começo da vez atual (ou ao parar).
    required Duration black,

    /// De quem é o relógio que está correndo. Nulo: relógio parado.
    Side? running,

    /// Quando a vez de [running] começou.
    DateTime? turnStartedAt,
  }) = _ClockState;

  const ClockState._();

  Duration of(Side side) => side == Side.white ? white : black;
}
