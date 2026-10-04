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
  }) = _GameMode;

  const GameMode._();

  /// O lado da máquina. Nulo quando o jogador move os dois lados.
  Side? get machineSide =>
      opponent.isMachine ? (userSide ?? Side.white).opposite : null;
}
