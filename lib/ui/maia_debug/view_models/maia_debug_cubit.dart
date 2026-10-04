import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/maia/maia_repository.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/move_prediction.dart';
import '../../../domain/use_cases/game_rules.dart';

part 'maia_debug_cubit.freezed.dart';

enum MaiaDebugStatus {
  idle,
  running,
  done,

  /// O FEN digitado não descreve uma posição válida.
  invalidPosition,

  /// O modelo não respondeu.
  failed,
}

@freezed
abstract class MaiaDebugState with _$MaiaDebugState {
  const factory MaiaDebugState({
    @Default(MaiaDebugState.defaultFen) String fen,
    @Default(1400) int level,
    @Default(MaiaDebugStatus.idle) MaiaDebugStatus status,

    /// A última previsão, da posição e do nível em que foi pedida.
    MovePrediction? prediction,
  }) = _MaiaDebugState;

  /// O final de torre contra rei: uma posição em que o nível muda a jogada.
  static const defaultFen = '8/8/8/4k3/8/8/8/R3K3 w - - 0 1';
}

/// Tela de depuração do Maia: avalia uma posição num nível e mostra os lances
/// prováveis e o tempo da conta no aparelho.
class MaiaDebugCubit extends Cubit<MaiaDebugState> {
  MaiaDebugCubit(this._maia) : super(const MaiaDebugState());

  final MaiaRepository _maia;

  void setFen(String fen) => emit(state.copyWith(fen: fen.trim()));

  void setLevel(int level) =>
      emit(state.copyWith(level: MaiaLevels.nearest(level)));

  Future<void> evaluate() async {
    if (state.status == MaiaDebugStatus.running) return;
    final position = GameRules.fromFen(state.fen);
    if (position == null) {
      emit(
        state.copyWith(
          status: MaiaDebugStatus.invalidPosition,
          prediction: null,
        ),
      );
      return;
    }
    emit(state.copyWith(status: MaiaDebugStatus.running));
    try {
      final prediction = await _maia.predict(position, level: state.level);
      if (isClosed) return;
      emit(
        state.copyWith(status: MaiaDebugStatus.done, prediction: prediction),
      );
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(status: MaiaDebugStatus.failed, prediction: null));
    }
  }
}
