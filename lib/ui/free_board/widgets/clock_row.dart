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

  /// Altura da fileira, para a tela reservar o espaço do tabuleiro.
  static const height = PlayersRow.height;

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
      final clock = state.clock;
      return PlayerEntry(
        side: side,
        name: name,
        time: clock == null ? null : state.timeOf(side),
        running: clock?.running == side,
        clockKey: FreeBoardKeys.clock(side),
        timeKey: FreeBoardKeys.clockTime(side),
        turnKey: FreeBoardKeys.turn,
        // Sem relógio, a vez aparece na linha de quem joga.
        turnLabel:
            clock == null && state.end == null && state.position.turn == side
            ? (side == mode.userSide && mode.opponent.isMachine
                  ? l10n.gameYourTurn
                  : side == Side.white
                  ? l10n.freeBoardWhiteToMove
                  : l10n.freeBoardBlackToMove)
            : null,
      );
    }

    return PlayersRow(
      players: [for (final side in sides) entry(side)],
      board: board,
    );
  }
}
