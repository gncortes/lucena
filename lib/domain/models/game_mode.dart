import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'endgame_position.dart';
import 'game_setup.dart';

part 'game_mode.freezed.dart';

/// De que partida se trata: contra quem, de que lado o jogador está e, num
/// treino, o objetivo e a posição do catálogo.
@freezed
abstract class GameMode with _$GameMode {
  const factory GameMode({
    @Default(OpponentKind.twoPlayers) OpponentKind opponent,

    /// O nível do Maia, quando ele é o adversário.
    int? level,

    /// O lado do jogador. Nulo no tabuleiro livre.
    Side? userSide,

    /// O que o jogador precisa fazer. Nulo fora do treino.
    PositionGoal? goal,

    /// A posição do catálogo, para gravar a tentativa. Nula na posição
    /// personalizada.
    String? positionId,

    /// O desafio da Jornada, quando a partida é um.
    String? challengeId,

    /// O speedrun, a tentativa e a etapa (a partir de 0), quando a partida é
    /// uma etapa.
    String? speedrunId,
    int? speedrunAttemptId,
    int? speedrunStage,
  }) = _GameMode;

  const GameMode._();

  /// O lado da máquina. Nulo quando o jogador move os dois lados.
  bool get isSpeedrun => speedrunAttemptId != null;

  Side? get machineSide =>
      opponent.isMachine ? (userSide ?? Side.white).opposite : null;
}
