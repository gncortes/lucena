import 'package:freezed_annotation/freezed_annotation.dart';

import 'clock.dart';
import 'game_end.dart';
import 'game_setup.dart';

part 'attempt.freezed.dart';

/// Como a partida terminou para o jogador.
enum AttemptOutcome {
  win,
  draw,
  loss;

  String get code => name;

  static AttemptOutcome fromCode(String code) =>
      values.asNameMap()[code] ?? loss;
}

/// Uma partida de treino terminada, numa posição do catálogo: solta, num
/// desafio da Jornada ou numa etapa de speedrun.
@freezed
abstract class Attempt with _$Attempt {
  const factory Attempt({
    required String positionId,

    /// Quando a partida terminou.
    required DateTime playedAt,
    required AttemptOutcome outcome,

    /// O objetivo da posição foi cumprido.
    required bool fulfilled,
    required OpponentKind opponent,

    /// O nível do Maia, quando ele foi o adversário.
    int? opponentLevel,

    /// Quando a partida começou. Nulo nas partidas de antes da Jornada.
    DateTime? startedAt,

    /// A posição em que a partida começou (FEN) e os lances (UCI). Vazios nas
    /// partidas de antes da Jornada.
    String? startFen,
    @Default(<String>[]) List<String> moves,

    /// Como a partida terminou (mate, tempo, desistência...).
    GameEndReason? endReason,

    /// O tempo do jogador e o do adversário. Nulos sem relógio.
    TimeControl? userTime,
    TimeControl? opponentTime,

    /// Quanto o relógio do jogador gastou na partida. Nulo sem relógio.
    Duration? userClock,

    /// O desafio da Jornada, quando a partida foi um.
    String? challengeId,

    /// A tentativa de speedrun e a etapa (a partir de 0), quando a partida foi
    /// uma etapa.
    int? speedrunAttemptId,
    int? speedrunStage,
  }) = _Attempt;
}
