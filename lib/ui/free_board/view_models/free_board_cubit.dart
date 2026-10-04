import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/haptics/haptics_repository.dart';
import '../../../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/game_snapshot.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import 'free_board_state.dart';

export 'free_board_state.dart';

/// Tabuleiro livre: o jogador faz os lances dos dois lados, com ou sem relógio.
/// A partida é gravada a cada mudança e continua de onde parou se o app for
/// fechado.
class FreeBoardCubit extends Cubit<FreeBoardState> {
  /// Com [start], começa uma partida nova nessa posição; [playerSide] faz o
  /// jogador mover só as peças de um lado (e ver o tabuleiro por ele) e
  /// [clock] liga o relógio, já correndo. [orientation] é o lado que fica
  /// embaixo (sem ele, o do jogador ou as brancas).
  ///
  /// Sem [start], a tela espera [open] trazer a partida em andamento.
  FreeBoardCubit({
    required Now now,
    required this._haptics,
    required this._settings,
    required this._games,
    Position? start,
    Side? playerSide,
    Side? orientation,
    ClockConfig? clock,
  }) : _now = now,
       super(
         start == null
             ? const FreeBoardState(
                 start: GameRules.initial,
                 position: GameRules.initial,
                 ready: false,
               )
             : _fresh(
                 start: start,
                 playerSide: playerSide,
                 orientation: orientation ?? playerSide ?? Side.white,
                 clock: clock,
                 now: now(),
               ),
       );

  final Now _now;
  final HapticsRepository _haptics;
  final SettingsRepository _settings;
  final OngoingGameRepository _games;

  // Os lados que já receberam o aviso de pouco tempo.
  final _lowTimeWarned = <Side>{};

  // Depois que o jogador sai da tela, nada mais mexe na partida.
  bool _left = false;

  // As gravações em fila: uma termina antes de a próxima começar.
  Future<void> _saving = Future.value();

  /// A tela abriu. Partida nova (criada com posição) é só gravada; sem ela,
  /// continua a partida em andamento ou, se não há, começa uma do início.
  Future<void> open() async {
    if (!state.ready) {
      final snapshot = await _games.load();
      if (isClosed) return;
      final now = _now();
      emit(
        _restored(snapshot, now) ??
            _fresh(
              start: GameRules.initial,
              playerSide: null,
              orientation: Side.white,
              clock: null,
              now: now,
            ),
      );
      // A bandeira pode ter caído com o app fechado.
      tick();
    }
    _persist();
    await _saving;
  }

  /// Joga um lance de quem está na vez, seja do jogador ou do adversário.
  /// Lance ilegal ou com a partida terminada é ignorado.
  void play(Move move) {
    // A bandeira vale antes do lance: tempo esgotado não joga.
    tick();
    if (!_active || state.end != null) return;
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
          ucis: [...state.ucis, move.uci],
          lastMove: move,
          clock: clock,
        ),
        now,
      ),
    );
    _persist();
  }

  /// Atualiza os tempos pelo relógio do aparelho e confere a bandeira. A tela
  /// chama várias vezes por segundo; o resultado só depende do instante atual,
  /// então vale igual depois de o app ficar em segundo plano.
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
      _persist();
      return;
    }
    _warnLowTime(clock, now);
    emit(_timed(state, now));
  }

  /// Vira o tabuleiro: o lado de cima passa para baixo.
  void flip() {
    if (!_active) return;
    emit(state.copyWith(orientation: state.orientation.opposite));
    _persist();
  }

  /// Volta à posição em que o tabuleiro abriu, sem lances. O tabuleiro
  /// continua virado como estava e o relógio recomeça com o mesmo tempo.
  void newGame() => _restart(state.clock?.config);

  /// Recomeça a partida com o relógio [clock]. Nulo: sem relógio.
  void newGameWithClock(ClockConfig? clock) => _restart(clock);

  /// O jogador saiu da tela por conta própria: o relógio para e a partida fica
  /// guardada para quando ele voltar.
  Future<void> leave() async {
    if (!_active) return;
    _left = true;
    final clock = state.clock;
    if (clock != null) {
      final now = _now();
      emit(_timed(state.copyWith(clock: ClockEngine.stop(clock, now)), now));
    }
    _persist(onScreen: false);
    await _saving;
  }

  // A partida já foi lida do aparelho e o jogador continua na tela.
  bool get _active => state.ready && !_left;

  void _restart(ClockConfig? clock) {
    if (!_active) return;
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
    _persist();
  }

  // Grava a partida como está. Partida terminada sai da gravação: não há o
  // que continuar.
  void _persist({bool onScreen = true}) {
    final current = state;
    final snapshot = current.end != null
        ? null
        : GameSnapshot(
            startFen: current.start.fen,
            moves: current.ucis,
            orientation: current.orientation,
            playerSide: current.playerSide,
            clock: current.clock,
            onScreen: onScreen,
          );
    _saving = _saving.whenComplete(
      () => snapshot == null ? _games.clear() : _games.save(snapshot),
    );
  }

  // A partida gravada, refeita lance a lance. Nulo se não há gravação ou se
  // ela não fecha com as regras (aí a tela começa uma partida do início).
  static FreeBoardState? _restored(GameSnapshot? snapshot, DateTime now) {
    if (snapshot == null) return null;
    final start = GameRules.fromFen(snapshot.startFen);
    if (start == null) return null;
    var position = start;
    final moves = <String>[];
    Move? lastMove;
    for (final uci in snapshot.moves) {
      final move = Move.parse(uci);
      final played = move == null ? null : GameRules.play(position, move);
      if (played == null) return null;
      position = played.position;
      moves.add(played.san);
      lastMove = move;
    }
    var clock = snapshot.clock;
    // Relógio parado numa partida em andamento: o jogador tinha saído da tela.
    // Ao voltar, o relógio retoma do ponto em que parou.
    if (clock != null && GameRules.endOf(position) == null) {
      clock = ClockEngine.resume(clock, turn: position.turn, now: now);
    }
    return _timed(
      FreeBoardState(
        start: start,
        position: position,
        moves: moves,
        ucis: snapshot.moves,
        lastMove: lastMove,
        orientation: snapshot.orientation,
        playerSide: snapshot.playerSide,
        clock: clock,
      ),
      now,
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
