import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../domain/use_cases/game_rules.dart';

class BoardControlsState {
  const BoardControlsState({
    this.position = GameRules.initial,
    this.lastMove,
    this.leaving = false,
  });

  final Position position;
  final Move? lastMove;
  final bool leaving;
  bool get moved => position.fen != GameRules.initial.fen;
}

/// Familiarização com o controle do tabuleiro, sem partida ou avaliação.
class BoardControlsCubit extends Cubit<BoardControlsState> {
  BoardControlsCubit(this._onboarding) : super(const BoardControlsState());

  final OnboardingRepository _onboarding;
  bool _saving = false;
  Future<void> _writes = Future<void>.value();

  Future<void> load() => _writes = _load();

  Future<void> _load() async {
    final saved = await _onboarding.load();
    final position =
        GameRules.fromFen(saved.boardControlsFen ?? '') ?? GameRules.initial;
    if (isClosed) return;
    emit(BoardControlsState(position: position));
    await _onboarding.save(saved.copyWith(boardControlsOpen: true));
  }

  void play(Move move) {
    final played = GameRules.play(state.position, move);
    if (played == null || state.leaving) return;
    emit(BoardControlsState(position: played.position, lastMove: move));
    _writes = _writes.then((_) async {
      final saved = await _onboarding.load();
      await _onboarding.save(
        saved.copyWith(
          boardControlsFen: played.position.fen,
          boardControlsOpen: true,
        ),
      );
    });
  }

  Future<void> finish({bool completed = true}) async {
    if (_saving || state.leaving) return;
    _saving = true;
    try {
      await _writes;
      final saved = await _onboarding.load();
      await _onboarding.save(
        saved.copyWith(
          boardControlsDone: completed || saved.boardControlsDone,
          boardControlsOpen: false,
        ),
      );
      if (!isClosed) {
        emit(
          BoardControlsState(
            position: state.position,
            lastMove: state.lastMove,
            leaving: true,
          ),
        );
      }
    } finally {
      _saving = false;
    }
  }
}
