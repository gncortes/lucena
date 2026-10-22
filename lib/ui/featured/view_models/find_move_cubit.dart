import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/use_cases/game_rules.dart';

enum FindMovePhase {
  /// Esperando o lance.
  asking,

  /// O lance não foi o certo: pode tentar de novo.
  wrong,

  /// Achou o lance.
  solved,

  /// Viu a resposta.
  revealed,
}

/// O "ache o lance": um lance só, sem adversário e sem relógio.
class FindMoveState {
  const FindMoveState({
    this.phase = FindMovePhase.asking,
    this.hint = false,
    this.attempts = 0,
  });

  final FindMovePhase phase;

  /// A dica (a casa de onde o lance sai) está aberta.
  final bool hint;
  final int attempts;

  bool get finished =>
      phase == FindMovePhase.solved || phase == FindMovePhase.revealed;

  FindMoveState copyWith({FindMovePhase? phase, bool? hint, int? attempts}) =>
      FindMoveState(
        phase: phase ?? this.phase,
        hint: hint ?? this.hint,
        attempts: attempts ?? this.attempts,
      );
}

class FindMoveCubit extends Cubit<FindMoveState> {
  FindMoveCubit({required this.endgame, required this._progress})
    : super(const FindMoveState());

  final FeaturedEndgame endgame;
  final FeaturedProgressRepository _progress;

  /// O lance certo (o primeiro da lista), em UCI.
  String? get answer => endgame.solutions.firstOrNull;

  /// O lance certo em notação algébrica, para mostrar.
  String? get answerSan {
    final uci = answer;
    final position = GameRules.fromFen(endgame.fen);
    final move = uci == null ? null : Move.parse(uci);
    if (position == null || move == null) return null;
    return GameRules.play(position, move)?.san;
  }

  /// A peça que dá o lance certo, para a dica ("mexa o rei"). Não entrega a
  /// casa.
  Role? get hintRole {
    final position = GameRules.fromFen(endgame.fen);
    final uci = answer;
    final move = uci == null ? null : Move.parse(uci);
    if (position == null || move is! NormalMove) return null;
    return position.board.roleAt(move.from);
  }

  /// O lance certo como lance do tabuleiro, para destacá-lo ao mostrar a
  /// resposta.
  NormalMove? get answerMove {
    final uci = answer;
    final move = uci == null ? null : Move.parse(uci);
    return move is NormalMove ? move : null;
  }

  /// Há uma dica útil: a do próprio final, ou a da peça quando o lado tem mais
  /// que o rei ("mexa o rei" não ajuda a quem só tem o rei).
  bool get hasHint {
    if (!endgame.hint.isEmpty) return true;
    final position = GameRules.fromFen(endgame.fen);
    if (position == null || hintRole == null) return false;
    return position.board.bySide(position.turn).size > 1;
  }

  /// O jogador fez [move]. Certo ou errado, o tabuleiro volta à posição.
  Future<void> play(Move move) async {
    if (state.finished) return;
    if (endgame.solutions.contains(move.uci)) {
      emit(state.copyWith(phase: FindMovePhase.solved));
      await _progress.markPlayed(endgame.id);
    } else {
      emit(
        state.copyWith(
          phase: FindMovePhase.wrong,
          attempts: state.attempts + 1,
        ),
      );
    }
  }

  void showHint() {
    if (state.finished) return;
    emit(state.copyWith(hint: true));
  }

  Future<void> reveal() async {
    if (state.finished) return;
    emit(state.copyWith(phase: FindMovePhase.revealed));
    await _progress.markPlayed(endgame.id);
  }

  /// Depois de errar ou de ver a resposta, o jogador tenta de novo (o
  /// tabuleiro volta à posição).
  void retry() {
    switch (state.phase) {
      case FindMovePhase.wrong:
        emit(state.copyWith(phase: FindMovePhase.asking));
      case FindMovePhase.revealed:
        emit(
          state.copyWith(
            phase: FindMovePhase.asking,
            hint: false,
            attempts: state.attempts + 1,
          ),
        );
      case FindMovePhase.asking || FindMovePhase.solved:
        break;
    }
  }
}
