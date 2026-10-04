import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/training/training_repository.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/use_cases/position_validation.dart';

part 'custom_position_cubit.freezed.dart';

@freezed
abstract class CustomPositionState with _$CustomPositionState {
  const factory CustomPositionState({
    /// O FEN como está no campo de texto.
    @Default(CustomPositionCubit.startFen) String fen,

    /// O desenho das peças do último FEN que deu para ler, que o editor mostra
    /// enquanto o texto está incompleto.
    @Default(CustomPositionCubit.startBoard) String board,
    @Default(Side.white) Side turn,
    @Default(PositionGoal.win) PositionGoal goal,

    /// A posição pronta para jogar, quando não há problema.
    Position? position,
    PositionProblem? problem,

    /// Falso até o rascunho ser lido.
    @Default(false) bool ready,
  }) = _CustomPositionState;
}

/// A posição montada pelo jogador: FEN colado ou editor. O rascunho fica
/// gravado e volta se o app for fechado.
class CustomPositionCubit extends Cubit<CustomPositionState> {
  CustomPositionCubit(this._training) : super(const CustomPositionState());

  /// Só os dois reis: o ponto de partida do editor.
  static const startBoard = '4k3/8/8/8/8/8/8/4K3';
  static const startFen = '$startBoard w - - 0 1';

  final TrainingRepository _training;

  Future<void> load() async {
    final draft = await _training.loadCustomDraft();
    if (isClosed) return;
    _apply(
      draft?.fen ?? startFen,
      goal: draft?.goal ?? PositionGoal.win,
      save: false,
    );
  }

  /// O jogador digitou ou colou um FEN.
  void setFen(String fen) => _apply(fen.trim());

  /// O editor mudou as peças: o FEN acompanha, com a mesma vez de jogar.
  void setBoard(String board) => _apply(_compose(board, state.turn));

  void setTurn(Side turn) => _apply(_compose(state.board, turn));

  void setGoal(PositionGoal goal) => _apply(state.fen, goal: goal);

  /// Tira todas as peças menos os dois reis.
  void clear() => _apply(_compose(startBoard, state.turn));

  // Posição montada no editor: sem roque nem en passant.
  static String _compose(String board, Side turn) =>
      '$board ${turn == Side.white ? 'w' : 'b'} - - 0 1';

  void _apply(String fen, {PositionGoal? goal, bool save = true}) {
    final check = PositionValidation.check(fen);
    var board = state.board;
    var turn = state.turn;
    try {
      final setup = Setup.parseFen(fen);
      board = setup.board.fen;
      turn = setup.turn;
    } on FenException {
      // Texto incompleto: o editor fica com as últimas peças lidas.
    }
    emit(
      CustomPositionState(
        fen: fen,
        board: board,
        turn: turn,
        goal: goal ?? state.goal,
        position: check.position,
        problem: check.problem,
        ready: true,
      ),
    );
    if (save) _training.saveCustomDraft((fen: fen, goal: state.goal));
  }
}
