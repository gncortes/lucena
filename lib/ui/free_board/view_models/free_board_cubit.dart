import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/use_cases/game_rules.dart';
import 'free_board_state.dart';

export 'free_board_state.dart';

/// Tabuleiro livre: o jogador faz os lances dos dois lados.
class FreeBoardCubit extends Cubit<FreeBoardState> {
  /// Sem [start], abre na posição inicial do xadrez. Com [playerSide], o
  /// jogador só move as peças desse lado e vê o tabuleiro por ele.
  FreeBoardCubit({Position start = GameRules.initial, Side? playerSide})
    : super(
        FreeBoardState(
          start: start,
          position: start,
          playerSide: playerSide,
          orientation: playerSide ?? Side.white,
        ),
      );

  /// Joga um lance de quem está na vez, seja do jogador ou do adversário.
  /// Lance ilegal ou com a partida terminada é ignorado.
  void play(Move move) {
    if (state.end != null) return;
    final played = GameRules.play(state.position, move);
    if (played == null) return;
    emit(
      state.copyWith(
        position: played.position,
        moves: [...state.moves, played.san],
        lastMove: move,
      ),
    );
  }

  /// Vira o tabuleiro: o lado de cima passa para baixo.
  void flip() {
    emit(state.copyWith(orientation: state.orientation.opposite));
  }

  /// Volta à posição em que o tabuleiro abriu, sem lances. O tabuleiro
  /// continua virado como estava.
  void newGame() {
    emit(
      FreeBoardState(
        start: state.start,
        position: state.start,
        playerSide: state.playerSide,
        orientation: state.orientation,
      ),
    );
  }
}
