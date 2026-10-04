import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/use_cases/game_rules.dart';
import 'free_board_state.dart';

export 'free_board_state.dart';

/// Tabuleiro livre: o jogador faz os lances dos dois lados.
class FreeBoardCubit extends Cubit<FreeBoardState> {
  /// Sem [start], abre na posição inicial do xadrez.
  FreeBoardCubit({Position start = GameRules.initial})
    : super(FreeBoardState(start: start, position: start));

  /// Joga um lance. Lance ilegal ou com a partida terminada é ignorado.
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

  /// Volta à posição em que o tabuleiro abriu, sem lances.
  void newGame() {
    emit(FreeBoardState(start: state.start, position: state.start));
  }
}
