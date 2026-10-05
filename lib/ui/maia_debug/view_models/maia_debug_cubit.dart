import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/maia/maia_repository.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/maia_timing.dart';
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

    /// A última medição de velocidade neste aparelho.
    MaiaTiming? timing,
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

  /// Quantas contas entram numa medição de velocidade.
  static const measureRuns = 10;

  Future<void> evaluate() => _run(measuring: false);

  /// Mede a velocidade do Maia no aparelho: [measureRuns] contas seguidas da
  /// posição e do nível escolhidos.
  Future<void> measure() => _run(measuring: true);

  Future<void> _run({required bool measuring}) async {
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
      // Na medição, esta primeira conta fica de fora: é ela que liga o modelo.
      var prediction = await _maia.predict(position, level: state.level);
      final times = <Duration>[];
      for (var run = 0; measuring && run < measureRuns; run++) {
        if (isClosed) return;
        prediction = await _maia.predict(position, level: state.level);
        times.add(prediction.elapsed);
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          status: MaiaDebugStatus.done,
          prediction: prediction,
          timing: measuring ? MaiaTiming.of(times) : state.timing,
        ),
      );
    } on Object {
      if (isClosed) return;
      emit(state.copyWith(status: MaiaDebugStatus.failed, prediction: null));
    }
  }
}
