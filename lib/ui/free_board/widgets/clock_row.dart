import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../view_models/free_board_state.dart';
import '../view_models/talk_cubit.dart';
import '../../core/widgets/game_clock.dart';
import '../../core/widgets/character_avatar.dart';

/// Uma fileira de jogadores com os seus relógios: a de um lado só (retrato,
/// nome e o relógio na ponta) ou a dos dois juntos, brancas primeiro. Sem
/// relógio na partida, a ponta mostra de quem é a vez.
class ClockRow extends StatelessWidget {
  const ClockRow({
    required this.sides,
    required this.state,
    required this.board,
    this.talk,
    super.key,
  });

  /// Altura da fileira, para a tela reservar o espaço do tabuleiro: a da
  /// faixa com a linha de detalhe (CompJogador, 68).
  static const height = PlayersRow.detailedHeight;

  final List<Side> sides;
  final FreeBoardState state;

  /// A aparência escolhida: o retrato de cada lado é o peão dele, numa casa
  /// do tabuleiro.
  final BoardSettings board;

  /// O personagem do adversário: o nome dele no lado da máquina.
  final TalkState? talk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mode = state.mode;
    final nickname = context.select(
      (ProfileCubit cubit) => cubit.state?.nickname ?? '',
    );
    PlayerEntry entry(Side side) {
      // O lado da máquina leva o nome dela (`Maia 1400`, `Stockfish`).
      final character = side == mode.machineSide ? talk?.character : null;
      final name = character != null
          ? character.name
          : side == mode.machineSide
          ? mode.opponent.label(l10n, level: mode.level)
          // Contra a máquina, o lado do jogador leva o apelido dele.
          : side == mode.userSide && mode.opponent.isMachine
          ? (nickname.isEmpty ? l10n.profileNicknameDefault : nickname)
          : side == Side.white
          ? l10n.sideWhite
          : l10n.sideBlack;
      // Embaixo do nome: o nível do personagem e o rating do jogador
      // (CompJogador, `Nível 1000` e `1164`). O Stockfish não tem nível, e
      // o nome do Maia sem personagem já o traz.
      final level = mode.level;
      final rating = state.userRating;
      final detail = side == mode.machineSide
          ? (character != null && !(talk?.isEngine ?? false) && level != null
                ? l10n.journeyOpponentLevel('$level')
                : null)
          : side == mode.userSide && mode.opponent.isMachine && rating != null
          ? '$rating'
          : null;
      final clock = state.clock;
      return PlayerEntry(
        detail: detail,
        detailKey: FreeBoardKeys.playerDetail(side),
        side: side,
        name: name,
        time: clock == null ? null : state.timeOf(side),
        // Partida acabada: nenhum relógio ativo (TimeDisplayState.paused).
        running: state.end == null && clock?.running == side,
        clockKey: FreeBoardKeys.clock(side),
        timeKey: FreeBoardKeys.clockTime(side),
        turnKey: FreeBoardKeys.turn,
        // Sem relógio, a vez é o anel no retrato de quem joga.
        isTurn: state.end == null && state.position.turn == side,
        portrait: character == null
            ? null
            : CharacterAvatar(
                key: FreeBoardKeys.characterAvatar(talk!.emotion),
                character: character,
                emotion: talk!.isEngine ? null : talk!.emotion,
                size: 44,
              ),
      );
    }

    return PlayersRow(
      players: [for (final side in sides) entry(side)],
      board: board,
      enterClocks: true,
      compactClocks: sides.length == 2,
      detailed: true,
    );
  }
}
