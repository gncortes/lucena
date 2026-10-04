import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/training/training_repository.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_setup.dart';

part 'game_setup_cubit.freezed.dart';

/// Os limites dos seletores de tempo.
abstract final class SetupLimits {
  static const maxMinutes = 180;
  static const maxIncrement = 60;
}

@freezed
abstract class GameSetupState with _$GameSetupState {
  const factory GameSetupState({
    /// A posição de início.
    required Position position,
    required PositionGoal goal,

    /// O lado do jogador. Começa no lado que joga na posição.
    required Side userSide,
    @Default(GameSetup()) GameSetup setup,

    /// Falso até a última configuração ser lida.
    @Default(false) bool ready,
  }) = _GameSetupState;

  const GameSetupState._();

  /// Relógio ligado com tempo inicial zero em algum lado: não dá para começar.
  bool get hasZeroTime =>
      setup.clock &&
      (setup.userTime.initial == Duration.zero ||
          setup.opponentTime.initial == Duration.zero);

  bool get canStart => ready && !hasZeroTime;

  /// O tempo das brancas e o das pretas, como o tabuleiro recebe
  /// (`segundos+incremento`). Nulos sem relógio.
  ({String? white, String? black}) get clockCodes {
    if (!setup.clock) return (white: null, black: null);
    final user = setup.userTime.code;
    final opponent = setup.opponentTime.code;
    return userSide == Side.white
        ? (white: user, black: opponent)
        : (white: opponent, black: user);
  }
}

/// A configuração da partida antes de começar: lado, adversário e relógio. A
/// configuração (sem o lado, que depende da posição) fica gravada.
class GameSetupCubit extends Cubit<GameSetupState> {
  GameSetupCubit(
    this._training, {
    required Position position,
    required PositionGoal goal,
  }) : super(
         GameSetupState(
           position: position,
           goal: goal,
           userSide: position.turn,
         ),
       );

  final TrainingRepository _training;

  Future<void> load() async {
    final setup = await _training.loadSetup();
    if (isClosed) return;
    emit(state.copyWith(setup: setup, ready: true));
  }

  void setUserSide(Side side) => emit(state.copyWith(userSide: side));

  Future<void> setClock({required bool enabled}) =>
      _update(state.setup.copyWith(clock: enabled));

  Future<void> setOpponent(OpponentKind opponent) =>
      _update(state.setup.copyWith(opponent: opponent));

  Future<void> setUserTime({int? minutes, int? increment}) => _update(
    state.setup.copyWith(
      userTime: _time(state.setup.userTime, minutes, increment),
    ),
  );

  Future<void> setOpponentTime({int? minutes, int? increment}) => _update(
    state.setup.copyWith(
      opponentTime: _time(state.setup.opponentTime, minutes, increment),
    ),
  );

  static TimeControl _time(TimeControl time, int? minutes, int? increment) {
    return TimeControl(
      initial: minutes == null
          ? time.initial
          : Duration(minutes: minutes.clamp(0, SetupLimits.maxMinutes)),
      increment: increment == null
          ? time.increment
          : Duration(seconds: increment.clamp(0, SetupLimits.maxIncrement)),
    );
  }

  // A configuração muda na hora e é gravada em seguida.
  Future<void> _update(GameSetup setup) async {
    emit(state.copyWith(setup: setup));
    await _training.saveSetup(setup);
  }
}
