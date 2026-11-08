import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';
import '../../../domain/models/find_move_checkpoint.dart';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/use_cases/game_rules.dart';

export '../../../domain/models/find_move_checkpoint.dart' show FindMovePhase;

/// O "ache o lance": um lance só, sem adversário e sem relógio.
class FindMoveState {
  const FindMoveState({
    this.phase = FindMovePhase.asking,
    this.hint = false,
    this.attempts = 0,
    this.saving,
    this.failure,
  });

  final String? saving;
  final LoadFailure? failure;
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
  FindMoveCubit({
    required this.endgame,
    required this._progress,
    FindMoveCheckpoint? initial,
  }) : super(
         initial != null && initial.matches(endgame)
             ? FindMoveState(
                 phase: initial.phase,
                 hint: initial.hint,
                 attempts: initial.attempts,
               )
             : const FindMoveState(),
       );

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

  FindMoveState? _pending;
  String? _pendingAction;

  bool get _blocked =>
      state.finished || state.saving != null || _pending != null;

  Future<void> _save(FindMoveState candidate, String action) async {
    if (state.saving != null || isClosed) return;
    _pending = candidate;
    _pendingAction = action;
    emit(
      FindMoveState(
        phase: state.phase,
        hint: state.hint,
        attempts: state.attempts,
        saving: action,
      ),
    );
    try {
      await _progress.saveFindMove(
        endgame.id,
        FindMoveCheckpoint(
          fen: endgame.fen,
          solutions: List.unmodifiable(endgame.solutions),
          phase: candidate.phase,
          hint: candidate.hint,
          attempts: candidate.attempts,
        ),
      );
      _pending = null;
      _pendingAction = null;
      if (!isClosed) emit(candidate);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) {
        emit(
          FindMoveState(
            phase: state.phase,
            hint: state.hint,
            attempts: state.attempts,
            failure: LoadFailure.of(error),
          ),
        );
      }
    }
  }

  Future<void> retrySave() async {
    final candidate = _pending;
    if (candidate != null) await _save(candidate, _pendingAction!);
  }

  Future<void> play(Move move) async {
    if (_blocked) return;
    final correct = endgame.solutions.contains(move.uci);
    await _save(
      state.copyWith(
        phase: correct ? FindMovePhase.solved : FindMovePhase.wrong,
        attempts: correct ? state.attempts : state.attempts + 1,
      ),
      'play',
    );
  }

  Future<void> showHint() async {
    if (_blocked || state.hint) return;
    await _save(state.copyWith(hint: true), 'hint');
  }

  Future<void> reveal() async {
    if (_blocked) return;
    await _save(state.copyWith(phase: FindMovePhase.revealed), 'answer');
  }

  Future<void> retry() async {
    if (state.saving != null || _pending != null) return;
    switch (state.phase) {
      case FindMovePhase.wrong:
        await _save(state.copyWith(phase: FindMovePhase.asking), 'retry');
      case FindMovePhase.revealed:
        await _save(
          state.copyWith(
            phase: FindMovePhase.asking,
            hint: false,
            attempts: state.attempts + 1,
          ),
          'retry',
        );
      case FindMovePhase.asking || FindMovePhase.solved:
        break;
    }
  }
}
