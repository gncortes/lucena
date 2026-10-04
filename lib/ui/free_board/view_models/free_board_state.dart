import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/use_cases/game_rules.dart';

part 'free_board_state.freezed.dart';

@freezed
abstract class FreeBoardState with _$FreeBoardState {
  const factory FreeBoardState({
    /// A posição em que o tabuleiro abriu; "nova partida" volta para ela.
    required Position start,

    /// A posição atual.
    required Position position,

    /// Falso enquanto a partida em andamento ainda está sendo lida do aparelho.
    @Default(true) bool ready,

    /// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
    @Default(<String>[]) List<String> moves,

    /// Os mesmos lances em UCI (`e2e4`, `g1f3`), como são gravados.
    @Default(<String>[]) List<String> ucis,

    /// O último lance, para o tabuleiro destacar.
    Move? lastMove,

    /// O lado que aparece embaixo no tabuleiro.
    @Default(Side.white) Side orientation,

    /// O lado que o jogador move. Nulo: ele move os dois.
    Side? playerSide,

    /// O relógio da partida. Nulo: partida sem relógio.
    ClockState? clock,

    /// Quanto falta para cada lado, já arredondado como aparece na tela. Só
    /// valem com [clock].
    @Default(Duration.zero) Duration whiteTime,
    @Default(Duration.zero) Duration blackTime,

    /// O fim que não vem do tabuleiro: bandeira ou desistência.
    GameEnd? forcedEnd,

    /// Contra quem, de que lado e, num treino, com que objetivo.
    @Default(GameMode()) GameMode mode,

    /// A máquina está escolhendo o lance.
    @Default(false) bool machineThinking,
  }) = _FreeBoardState;

  const FreeBoardState._();

  /// Como a partida terminou. Nulo enquanto ela continua.
  GameEnd? get end => forcedEnd ?? GameRules.endOf(position);

  /// Como a partida terminou para o jogador. Nulo enquanto ela continua ou
  /// fora do treino.
  AttemptOutcome? get outcome {
    final end = this.end;
    final user = mode.userSide;
    if (end == null || user == null) return null;
    final winner = end.winner;
    if (winner == null) return AttemptOutcome.draw;
    return winner == user ? AttemptOutcome.win : AttemptOutcome.loss;
  }

  /// O objetivo do treino foi cumprido. Nulo enquanto a partida continua ou
  /// fora do treino.
  bool? get fulfilled {
    final outcome = this.outcome;
    final goal = mode.goal;
    if (outcome == null || goal == null) return null;
    return switch (goal) {
      PositionGoal.win => outcome == AttemptOutcome.win,
      PositionGoal.draw => outcome != AttemptOutcome.loss,
    };
  }

  /// Quanto falta para [side], como aparece na tela.
  Duration timeOf(Side side) => side == Side.white ? whiteTime : blackTime;
}
