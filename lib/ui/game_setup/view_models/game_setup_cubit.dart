import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/pace/pace_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/training/training_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/pace.dart';
import '../../../routing/routes.dart';

part 'game_setup_cubit.freezed.dart';

/// Os limites do tempo de cada lado.
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

    /// A posição do catálogo. Nula na posição personalizada.
    String? positionId,

    /// As partidas já jogadas nesta posição, da mais recente para a mais
    /// antiga.
    @Default(<Attempt>[]) List<Attempt> attempts,

    /// O lado do jogador. Começa no lado que joga na posição.
    required Side userSide,
    @Default(GameSetup()) GameSetup setup,

    /// O nível do Maia mais próximo do rating do jogador.
    @Default(MaiaLevels.min) int suggestedLevel,

    /// O rating do jogador, quando ele já tem partidas que contaram. Nulo: a
    /// sugestão vem da faixa do perfil.
    int? rating,

    /// Os ritmos nomeados (`1+0`, `3+2`...).
    @Default(<NamedTimeControl>[]) List<NamedTimeControl> paces,

    /// Os personagens, um por nível do Maia.
    @Default(<Character>[]) List<Character> characters,

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

  /// O ritmo nomeado em uso: relógio ligado com o mesmo tempo dos dois lados.
  NamedTimeControl? get pace {
    if (!setup.clock || setup.userTime != setup.opponentTime) return null;
    for (final pace in paces) {
      if (pace.time == setup.userTime) return pace;
    }
    return null;
  }

  /// O nível do Maia: o escolhido ou, sem escolha, o sugerido pelo perfil.
  int get maiaLevel => setup.maiaLevel ?? suggestedLevel;

  /// Onde a partida abre: a posição, o lado, o adversário, o relógio e, no
  /// treino, o objetivo.
  String get gameRoute {
    final clocks = clockCodes;
    if (setup.blind && setup.opponent != OpponentKind.twoPlayers) {
      return Routes.blindAt(
        position.fen,
        user: userSide.name,
        opponent: setup.opponent.code,
        level: setup.opponent == OpponentKind.maia ? '$maiaLevel' : null,
        white: clocks.white,
        black: clocks.black,
      );
    }
    return Routes.freeBoardAt(
      position.fen,
      view: userSide.name,
      white: clocks.white,
      black: clocks.black,
      opponent: setup.opponent.code,
      level: setup.opponent == OpponentKind.maia ? '$maiaLevel' : null,
      user: userSide.name,
      goal: goal.code,
      position: positionId,
    );
  }

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
    required this._progress,
    required this._profile,
    this._rating,
    this._pace,
    this._characters,
    required Position position,
    required PositionGoal goal,
    String? positionId,
  }) : super(
         GameSetupState(
           position: position,
           goal: goal,
           positionId: positionId,
           userSide: position.turn,
         ),
       );

  final TrainingRepository _training;
  final ProgressRepository _progress;
  final ProfileRepository _profile;
  final RatingRepository? _rating;
  final PaceRepository? _pace;
  final CharacterRepository? _characters;

  Future<void> load() async {
    final setup = await _training.loadSetup();
    final profile = await _profile.load();
    // Com partidas contadas, a sugestão vem do rating; antes, da faixa.
    final history = await _rating?.history() ?? const [];
    final rating = history.isEmpty ? null : history.last.rating.rounded;
    final paces = (await _pace?.table())?.named ?? const <NamedTimeControl>[];
    final characters = await _characters?.characters() ?? const <Character>[];
    final positionId = state.positionId;
    final attempts = positionId == null
        ? const <Attempt>[]
        : await _progress.attemptsFor(positionId);
    if (isClosed) return;
    emit(
      state.copyWith(
        setup: setup,
        attempts: attempts,
        suggestedLevel: MaiaLevels.nearest(rating ?? profile.rating),
        rating: rating,
        paces: paces,
        characters: characters,
        ready: true,
      ),
    );
  }

  void setUserSide(Side side) => emit(state.copyWith(userSide: side));

  Future<void> setClock({required bool enabled}) =>
      _update(state.setup.copyWith(clock: enabled));

  /// Às cegas ou com o tabuleiro.
  Future<void> setBlind({required bool blind}) =>
      _update(state.setup.copyWith(blind: blind));

  Future<void> setOpponent(OpponentKind opponent) =>
      _update(state.setup.copyWith(opponent: opponent));

  /// Escolhe o nível do Maia (um dos [MaiaLevels.all]).
  Future<void> setMaiaLevel(int level) =>
      _update(state.setup.copyWith(maiaLevel: MaiaLevels.nearest(level)));

  /// Usa um ritmo nomeado: relógio ligado, o mesmo tempo para os dois.
  Future<void> setPace(NamedTimeControl pace) => _update(
    state.setup.copyWith(
      clock: true,
      userTime: pace.time,
      opponentTime: pace.time,
    ),
  );

  /// Usa um ritmo montado à mão: relógio ligado, um tempo para cada lado
  /// (dentro dos limites).
  Future<void> setTimes({
    required TimeControl user,
    required TimeControl opponent,
  }) => _update(
    state.setup.copyWith(
      clock: true,
      userTime: _limited(user),
      opponentTime: _limited(opponent),
    ),
  );

  static TimeControl _limited(TimeControl time) {
    return TimeControl(
      initial: Duration(
        seconds: time.initial.inSeconds.clamp(
          0,
          SetupLimits.maxMinutes * Duration.secondsPerMinute,
        ),
      ),
      increment: Duration(
        seconds: time.increment.inSeconds.clamp(0, SetupLimits.maxIncrement),
      ),
    );
  }

  // A configuração muda na hora e é gravada em seguida.
  Future<void> _update(GameSetup setup) async {
    emit(state.copyWith(setup: setup));
    await _training.saveSetup(setup);
  }
}
