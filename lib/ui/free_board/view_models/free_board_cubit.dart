import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/haptics/haptics_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import 'free_board_state.dart';

export 'free_board_state.dart';

/// Tabuleiro livre: o jogador faz os lances dos dois lados, com ou sem relógio.
class FreeBoardCubit extends Cubit<FreeBoardState> {
  /// Sem [start], abre na posição inicial do xadrez. Com [playerSide], o
  /// jogador só move as peças desse lado e vê o tabuleiro por ele. Com
  /// [clock], a partida abre com o relógio já correndo.
  FreeBoardCubit({
    required Now now,
    required this._haptics,
    required this._settings,
    Position start = GameRules.initial,
    Side? playerSide,
    ClockConfig? clock,
  }) : _now = now,
       super(
         _fresh(
           start: start,
           playerSide: playerSide,
           orientation: playerSide ?? Side.white,
           clock: clock,
           now: now(),
         ),
       );

  final Now _now;
  final HapticsRepository _haptics;
  final SettingsRepository _settings;

  // Os lados que já receberam o aviso de pouco tempo.
  final _lowTimeWarned = <Side>{};

  /// Joga um lance de quem está na vez, seja do jogador ou do adversário.
  /// Lance ilegal ou com a partida terminada é ignorado.
  void play(Move move) {
    // A bandeira vale antes do lance: tempo esgotado não joga.
    tick();
    if (state.end != null) return;
    final played = GameRules.play(state.position, move);
    if (played == null) return;
    final now = _now();
    var clock = state.clock;
    if (clock != null) {
      clock = ClockEngine.press(clock, now);
      if (GameRules.endOf(played.position) != null) {
        clock = ClockEngine.stop(clock, now);
      }
    }
    emit(
      _timed(
        state.copyWith(
          position: played.position,
          moves: [...state.moves, played.san],
          lastMove: move,
          clock: clock,
        ),
        now,
      ),
    );
  }

  /// Atualiza os tempos pelo relógio do aparelho e confere a bandeira. A tela
  /// chama várias vezes por segundo; o resultado só depende do instante atual.
  void tick() {
    final clock = state.clock;
    if (clock == null || clock.running == null) return;
    final now = _now();
    final flagged = ClockEngine.flagged(clock, now);
    if (flagged != null) {
      emit(
        _timed(
          state.copyWith(
            clock: ClockEngine.stop(clock, now),
            timeEnd: GameRules.timeoutEnd(state.position, flagged),
          ),
          now,
        ),
      );
      return;
    }
    _warnLowTime(clock, now);
    emit(_timed(state, now));
  }

  /// Vira o tabuleiro: o lado de cima passa para baixo.
  void flip() {
    emit(state.copyWith(orientation: state.orientation.opposite));
  }

  /// Volta à posição em que o tabuleiro abriu, sem lances. O tabuleiro
  /// continua virado como estava e o relógio recomeça com o mesmo tempo.
  void newGame() => _restart(state.clock?.config);

  /// Recomeça a partida com o relógio [clock]. Nulo: sem relógio.
  void newGameWithClock(ClockConfig? clock) => _restart(clock);

  void _restart(ClockConfig? clock) {
    _lowTimeWarned.clear();
    emit(
      _fresh(
        start: state.start,
        playerSide: state.playerSide,
        orientation: state.orientation,
        clock: clock,
        now: _now(),
      ),
    );
  }

  static FreeBoardState _fresh({
    required Position start,
    required Side? playerSide,
    required Side orientation,
    required ClockConfig? clock,
    required DateTime now,
  }) {
    return _timed(
      FreeBoardState(
        start: start,
        position: start,
        playerSide: playerSide,
        orientation: orientation,
        // Posição que já abre terminada (mate, afogado) não liga o relógio.
        clock: clock == null || GameRules.endOf(start) != null
            ? null
            : ClockEngine.start(clock, turn: start.turn, now: now),
      ),
      now,
    );
  }

  // O estado com os tempos da tela calculados para o instante [now].
  static FreeBoardState _timed(FreeBoardState state, DateTime now) {
    final clock = state.clock;
    if (clock == null) return state;
    Duration shown(Side side) =>
        ClockFormat.displayed(ClockEngine.remaining(clock, side, now));
    return state.copyWith(
      whiteTime: shown(Side.white),
      blackTime: shown(Side.black),
    );
  }

  // Um aviso por lado cada vez que o tempo dele fica curto. Jogando de um lado
  // só, o aviso é só para o relógio do jogador.
  void _warnLowTime(ClockState clock, DateTime now) {
    final running = clock.running;
    if (running == null) return;
    if (ClockEngine.remaining(clock, running, now) >= ClockEngine.lowTime) {
      _lowTimeWarned.remove(running);
      return;
    }
    if (!_lowTimeWarned.add(running)) return;
    final playerSide = state.playerSide;
    if (playerSide != null && playerSide != running) return;
    unawaited(_vibrateIfEnabled());
  }

  Future<void> _vibrateIfEnabled() async {
    final settings = await _settings.load();
    if (settings.clock.lowTimeVibration) await _haptics.lowTime();
  }
}
