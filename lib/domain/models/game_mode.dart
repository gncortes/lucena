import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'challenge_link.dart';
import 'endgame_position.dart';
import 'game_setup.dart';

import '../use_cases/marathon.dart';

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

    /// A partida é um desafio que veio de um link: o fim dela oferece
    /// compartilhar o resultado.
    @Default(false) bool fromLink,

    /// O link de origem, quando o desafio é fechado: o resultado leva o mesmo
    /// link (mesmo código, trava e modo). Nulo: o link se refaz da partida.
    ChallengeLink? link,

    /// O final em destaque, quando a partida é um (sem nota e sem anúncio).
    String? featuredId,

    /// O dia (`aaaa-mm-dd`), quando a partida é o final do dia (sem nota).
    String? dailyDate,
  }) = _GameMode;

  const GameMode._();

  /// Um final para jogar sem nota: o em destaque ou o do dia.
  bool get isUnratedFinal => featuredId != null || dailyDate != null;

  /// O lado da máquina. Nulo quando o jogador move os dois lados.
  bool get isSpeedrun => speedrunAttemptId != null;

  /// Uma etapa da Maratona: emenda na próxima sozinha, sem resultado no meio.
  bool get isMarathon => isSpeedrun && Marathon.isMarathon(speedrunId);

  Side? get machineSide =>
      opponent.isMachine ? (userSide ?? Side.white).opposite : null;
}
