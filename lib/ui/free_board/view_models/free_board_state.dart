import 'package:dartchess/dartchess.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../domain/models/game_end.dart';
import '../../../domain/use_cases/game_rules.dart';

part 'free_board_state.freezed.dart';

@freezed
abstract class FreeBoardState with _$FreeBoardState {
  const factory FreeBoardState({
    /// A posição em que o tabuleiro abriu; "nova partida" volta para ela.
    required Position start,

    /// A posição atual.
    required Position position,

    /// Os lances jogados, em notação algébrica (`e4`, `Nf3`, `O-O`).
    @Default(<String>[]) List<String> moves,

    /// O último lance, para o tabuleiro destacar.
    Move? lastMove,

    /// O lado que aparece embaixo no tabuleiro.
    @Default(Side.white) Side orientation,

    /// O lado que o jogador move. Nulo: ele move os dois.
    Side? playerSide,
  }) = _FreeBoardState;

  const FreeBoardState._();

  /// Como a partida terminou. Nulo enquanto ela continua.
  GameEnd? get end => GameRules.endOf(position);
}
