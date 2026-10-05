import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/draw/draw_offer_repository.dart';
import '../../../data/repositories/haptics/haptics_repository.dart';
import '../../../data/repositories/ongoing_game/ongoing_game_repository.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/clock.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/models/game_mode.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/game_snapshot.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/clock_format.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/think_time_policy.dart';
import 'free_board_state.dart';
import 'game_reporter.dart';

export 'free_board_state.dart';
export 'game_reporter.dart';

/// A partida: no tabuleiro livre o jogador faz os lances dos dois lados; no
/// treino, joga contra a máquina ou sozinho, com um objetivo. A partida é
/// gravada a cada mudança e continua de onde parou se o app for fechado; a
/// tentativa de treino é gravada quando a partida termina.
class FreeBoardCubit extends Cubit<FreeBoardState> {
  /// Com [start], começa uma partida nova nessa posição; [playerSide] faz o
  /// jogador mover só as peças de um lado (e ver o tabuleiro por ele) e
  /// [clock] liga o relógio, já correndo. [orientation] é o lado que fica
  /// embaixo (sem ele, o do jogador ou as brancas).
  ///
  /// [mode] diz contra quem e, num treino, com que objetivo; contra a máquina
  /// o jogador só move as peças do lado dele.
  ///
  /// Sem [start], a tela espera [open] trazer a partida em andamento.
  FreeBoardCubit({
    required Now now,
    required this._haptics,
    required this._settings,
    required this._games,
    required this._opponent,
    required this._progress,
    this._reporter,
    this._draws,
    this._speedruns,
    Position? start,
    Side? playerSide,
    Side? orientation,
    ClockConfig? clock,
    GameMode mode = const GameMode(),
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
                 playerSide: mode.opponent.isMachine
                     ? mode.userSide ?? playerSide
                     : playerSide,
                 orientation:
                     orientation ?? mode.userSide ?? playerSide ?? Side.white,
                 clock: clock,
                 mode: mode,
                 now: now(),
               ),
       );

  final Now _now;
  final HapticsRepository _haptics;
  final SettingsRepository _settings;
  final OngoingGameRepository _games;
  final OpponentRepository _opponent;
  final ProgressRepository _progress;

  // Conta a partida terminada no rating, nas mensagens e nas conquistas. Nulo:
  // só grava o histórico.
  final GameReporter? _reporter;

  // Quem responde as propostas de empate. Nulo: a máquina sempre recusa.
  final DrawOfferRepository? _draws;

  // As tentativas de speedrun: sair no meio de uma encerra a tentativa.
  final SpeedrunRepository? _speedruns;

  // Os lados que já receberam o aviso de pouco tempo.
  final _lowTimeWarned = <Side>{};

  // Depois que o jogador sai da tela, nada mais mexe na partida.
  bool _left = false;

  // As gravações em fila: uma termina antes de a próxima começar.
  Future<void> _saving = Future.value();

  // A tentativa desta partida já foi gravada.
  bool _recorded = false;

  // Quando o motor falhou pela última vez, para não pedir de novo sem parar.
  DateTime? _machineFailedAt;
  static const _machineRetry = Duration(seconds: 2);

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
              mode: const GameMode(),
              now: now,
            ),
      );
      // A bandeira pode ter caído com o app fechado.
      tick();
    }
    _changed();
    await _saving;
  }

  /// Espera as gravações em andamento (a partida e o histórico) terminarem.
  Future<void> saved() => _saving;

  /// O app voltou do segundo plano (ou a tela foi desbloqueada): os relógios
  /// são refeitos e, se for a vez da máquina sem pedido em andamento, ela
  /// volta a pensar.
  void resumed() {
    tick();
    _askMachine();
  }

  /// O jogador desiste: a partida termina na hora, mesmo na vez da máquina.
  void resign() {
    final user = state.mode.userSide;
    if (!_active || state.end != null || user == null) return;
    final now = _now();
    final clock = state.clock;
    emit(
      _timed(
        state.copyWith(
          clock: clock == null ? null : ClockEngine.stop(clock, now),
          forcedEnd: GameEnd(GameEndReason.resign, winner: user.opposite),
          machineThinking: false,
        ),
        now,
      ),
    );
    _changed();
  }

  /// O jogador propõe empate. A máquina só aceita quando está bem pior; se
  /// aceitar, a partida termina empatada na hora.
  Future<void> offerDraw() async {
    final machine = state.mode.machineSide;
    if (!_active || !state.canOfferDraw || machine == null) return;
    final startedAt = state.startedAt;
    emit(state.copyWith(drawOffer: DrawOffer.pending));
    var accepted = false;
    try {
      accepted =
          await _draws?.accepts(
            state.position,
            machine: machine,
            kind: state.mode.opponent,
            level: state.mode.level,
          ) ??
          false;
    } on Object {
      accepted = false;
    }
    // A partida acabou ou recomeçou enquanto a máquina pensava.
    if (isClosed || state.startedAt != startedAt) return;
    if (state.end != null) {
      emit(state.copyWith(drawOffer: DrawOffer.none));
      return;
    }
    if (!accepted) {
      emit(
        state.copyWith(
          drawOffer: DrawOffer.declined,
          drawDeclinedAt: state.ucis.length,
        ),
      );
      return;
    }
    final now = _now();
    final clock = state.clock;
    emit(
      _timed(
        state.copyWith(
          clock: clock == null ? null : ClockEngine.stop(clock, now),
          forcedEnd: const GameEnd(GameEndReason.drawAgreed),
          drawOffer: DrawOffer.accepted,
          machineThinking: false,
        ),
        now,
      ),
    );
    _changed();
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
    final turnStartedAt = state.turnStartedAt;
    var next = state.copyWith(
      position: played.position,
      moves: [...state.moves, played.san],
      ucis: [...state.ucis, move.uci],
      // O tempo deste lance: o que já tinha corrido antes de uma saída da
      // tela mais o que correu desde que a vez (re)começou.
      moveTimes: [
        ...state.moveTimes,
        state.turnElapsed +
            (turnStartedAt == null
                ? Duration.zero
                : now.difference(turnStartedAt)),
      ],
      turnElapsed: Duration.zero,
      turnStartedAt: now,
      repetitions: GameRules.repetitionsOf(state.start, [
        ...state.ucis,
        move.uci,
      ]),
      lastMove: move,
      // Lance novo: o tabuleiro volta para a partida.
      viewedPly: null,
      viewedPosition: null,
      viewedMove: null,
    );
    final clock = state.clock;
    if (clock != null) {
      final pressed = ClockEngine.press(clock, now);
      next = next.copyWith(
        clock: next.end == null ? pressed : ClockEngine.stop(pressed, now),
      );
    }
    // Com a partida terminada, o tempo da vez para.
    if (next.end != null) next = next.copyWith(turnStartedAt: null);
    emit(_timed(next, now));
    _changed();
  }

  /// Mostra a posição depois de [ply] lances, só para ver (0 é a de início):
  /// a partida não muda e o tabuleiro não aceita lances até voltar ao último.
  /// No último lance (ou além), volta para a partida.
  void view(int ply) {
    if (!state.ready) return;
    final target = ply.clamp(0, state.ucis.length);
    if (target == state.shownPly) return;
    if (target == state.ucis.length) {
      emit(
        state.copyWith(viewedPly: null, viewedPosition: null, viewedMove: null),
      );
      return;
    }
    var position = state.start;
    Move? last;
    for (final uci in state.ucis.take(target)) {
      final move = Move.parse(uci);
      final played = move == null ? null : GameRules.play(position, move);
      if (played == null) return;
      position = played.position;
      last = move;
    }
    emit(
      state.copyWith(
        viewedPly: target,
        viewedPosition: position,
        viewedMove: last,
      ),
    );
  }

  /// Um lance para trás e um para a frente na revisão.
  void viewPrevious() => view(state.shownPly - 1);

  void viewNext() => view(state.shownPly + 1);

  /// Atualiza os tempos pelo relógio do aparelho e confere a bandeira. A tela
  /// chama várias vezes por segundo; o resultado só depende do instante atual,
  /// então vale igual depois de o app ficar em segundo plano.
  void tick() {
    // O motor falhou há pouco: tenta de novo, com intervalo.
    if (_machineFailedAt != null) _askMachine();
    final clock = state.clock;
    if (clock == null || clock.running == null) return;
    final now = _now();
    final flagged = ClockEngine.flagged(clock, now);
    if (flagged != null) {
      emit(
        _timed(
          state.copyWith(
            clock: ClockEngine.stop(clock, now),
            forcedEnd: GameRules.timeoutEnd(state.position, flagged),
            machineThinking: false,
          ),
          now,
        ),
      );
      _changed();
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
    final now = _now();
    // O tempo do lance da vez para junto com o relógio.
    final turnStartedAt = state.turnStartedAt;
    var paused = state.copyWith(
      turnElapsed:
          state.turnElapsed +
          (turnStartedAt == null
              ? Duration.zero
              : now.difference(turnStartedAt)),
      turnStartedAt: null,
    );
    final clock = state.clock;
    if (clock != null) {
      paused = paused.copyWith(clock: ClockEngine.stop(clock, now));
    }
    emit(_timed(paused, now));
    _persist(onScreen: false);
    await _saving;
  }

  /// O jogador saiu do speedrun no meio: a tentativa termina aqui (fica no
  /// histórico, sem recorde) e a etapa que estava no tabuleiro não fica
  /// guardada para depois.
  Future<void> quitSpeedrun() async {
    final attemptId = state.mode.speedrunAttemptId;
    if (attemptId == null || _left) return;
    _left = true;
    final now = _now();
    final clock = state.clock;
    if (clock != null) {
      emit(_timed(state.copyWith(clock: ClockEngine.stop(clock, now)), now));
    }
    _saving = _saving.whenComplete(() async {
      await _speedruns?.abandon(attemptId, now);
      await _games.clear();
    });
    await _saving;
  }

  // A partida já foi lida do aparelho e o jogador continua na tela.
  bool get _active => state.ready && !_left;

  void _restart(ClockConfig? clock) {
    if (!_active) return;
    _lowTimeWarned.clear();
    _recorded = false;
    emit(
      _fresh(
        start: state.start,
        playerSide: state.playerSide,
        orientation: state.orientation,
        clock: clock,
        mode: state.mode,
        now: _now(),
      ),
    );
    _changed();
  }

  // Depois de cada mudança da partida: grava, registra a tentativa se ela
  // terminou e, se for a vez da máquina, pede o lance.
  void _changed() {
    _persist();
    _record();
    _askMachine();
  }

  void _record() {
    final positionId = state.mode.positionId;
    final outcome = state.outcome;
    final fulfilled = state.fulfilled;
    if (_recorded || positionId == null || outcome == null) return;
    if (fulfilled == null) return;
    _recorded = true;
    final mode = state.mode;
    final clock = state.clock;
    final user = mode.userSide ?? Side.white;
    final attempt = Attempt(
      positionId: positionId,
      playedAt: _now(),
      outcome: outcome,
      fulfilled: fulfilled,
      opponent: mode.opponent,
      opponentLevel: mode.opponent == OpponentKind.maia ? mode.level : null,
      startedAt: state.startedAt,
      startFen: state.start.fen,
      moves: state.ucis,
      moveTimes: state.moveTimes,
      userSide: mode.userSide,
      endReason: state.end?.reason,
      userTime: clock?.config.of(user),
      opponentTime: clock?.config.of(user.opposite),
      userClock: clock == null ? null : _spent(clock, user),
      challengeId: mode.challengeId,
      speedrunAttemptId: mode.speedrunAttemptId,
      speedrunStage: mode.speedrunStage,
    );
    _saving = _saving.whenComplete(() async {
      final gameId = await _progress.addAttempt(attempt);
      await _report(attempt, gameId: gameId, userSide: user);
    });
  }

  Future<void> _report(
    Attempt attempt, {
    required int gameId,
    required Side userSide,
  }) async {
    final reporter = _reporter;
    if (reporter == null) return;
    final startedAt = state.startedAt;
    try {
      final report = await reporter.report(
        attempt,
        gameId: gameId,
        userSide: userSide,
        drawGoal: state.mode.goal == PositionGoal.draw,
      );
      // A partida recomeçou enquanto a conta era feita: o resumo é da outra.
      if (isClosed || state.startedAt != startedAt) return;
      emit(state.copyWith(report: report));
    } on Object {
      // Sem o resumo a partida continua valendo: o histórico já foi gravado.
    }
  }

  // Quanto o relógio de [side] gastou na partida: o tempo inicial mais os
  // incrementos dos lances dele, menos o que sobrou.
  Duration _spent(ClockState clock, Side side) {
    final config = clock.config.of(side);
    // Os lances se alternam a partir de quem joga na posição inicial.
    final plies = state.ucis.length;
    final sideMoves = state.start.turn == side ? (plies + 1) ~/ 2 : plies ~/ 2;
    final left = ClockEngine.remaining(clock, side, _now());
    final spent = config.initial + config.increment * sideMoves - left;
    return spent.isNegative ? Duration.zero : spent;
  }

  // Pede o lance à máquina quando é a vez dela. O relógio dela corre enquanto
  // ela pensa, pelos instantes, como o do jogador.
  void _askMachine() {
    final side = state.mode.machineSide;
    if (side == null || !_active || isClosed) return;
    if (state.end != null || state.position.turn != side) return;
    if (state.machineThinking) return;
    final failedAt = _machineFailedAt;
    final now = _now();
    if (failedAt != null && now.difference(failedAt) < _machineRetry) return;
    final clock = state.clock;
    final thinkTime = ThinkTimePolicy.of(
      remaining: clock == null ? null : ClockEngine.remaining(clock, side, now),
      increment: clock?.config.of(side).increment ?? Duration.zero,
    );
    final asked = state.position;
    emit(state.copyWith(machineThinking: true));
    _opponent
        .pickMove(
          asked,
          thinkTime: thinkTime,
          kind: state.mode.opponent,
          level: state.mode.level,
          history: _recentPositions(),
          time: clock?.config.of(side),
        )
        .then(
          (move) => _machineAnswered(asked, move),
          onError: (Object _) => _machineFailed(asked),
        );
  }

  // As últimas posições da partida, da mais antiga para a atual: o Maia joga
  // olhando também as anteriores.
  List<Position> _recentPositions() {
    var position = state.start;
    final positions = [position];
    for (final uci in state.ucis) {
      final move = Move.parse(uci);
      final played = move == null ? null : GameRules.play(position, move);
      if (played == null) break;
      position = played.position;
      positions.add(position);
    }
    // A posição do estado é a mesma instância que a máquina recebe.
    positions.last = state.position;
    return positions.length > _historyLength
        ? positions.sublist(positions.length - _historyLength)
        : positions;
  }

  static const _historyLength = 8;

  void _machineAnswered(Position asked, Move? move) {
    if (isClosed) return;
    _machineFailedAt = null;
    // A partida mudou enquanto a máquina pensava (desistência, bandeira, nova
    // partida): a resposta não vale mais.
    final stillAsked = identical(state.position, asked) && state.end == null;
    if (state.machineThinking) emit(state.copyWith(machineThinking: false));
    if (!stillAsked || move == null) return;
    play(move);
  }

  void _machineFailed(Position asked) {
    if (isClosed) return;
    _machineFailedAt = _now();
    if (state.machineThinking) emit(state.copyWith(machineThinking: false));
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
            mode: current.mode,
            onScreen: onScreen,
            startedAt: current.startedAt,
            moveTimes: current.moveTimes,
            turnElapsed: current.turnElapsed,
            turnStartedAt: current.turnStartedAt,
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
    var restored = FreeBoardState(
      start: start,
      position: position,
      moves: moves,
      ucis: snapshot.moves,
      repetitions: GameRules.repetitionsOf(start, snapshot.moves),
      lastMove: lastMove,
      orientation: snapshot.orientation,
      playerSide: snapshot.playerSide,
      clock: snapshot.clock,
      mode: snapshot.mode,
      startedAt: snapshot.startedAt,
      // Gravação de antes do tempo por lance: os lances ficam sem tempo.
      moveTimes: snapshot.moveTimes.length == snapshot.moves.length
          ? snapshot.moveTimes
          : const [],
      turnElapsed: snapshot.turnElapsed,
      // Parado (o jogador tinha saído da tela), o tempo da vez volta a
      // correr agora; fechado à força, ele seguiu correndo.
      turnStartedAt: snapshot.turnStartedAt ?? now,
    );
    final clock = snapshot.clock;
    // Relógio parado numa partida em andamento: o jogador tinha saído da tela.
    // Ao voltar, o relógio retoma do ponto em que parou.
    if (clock != null && restored.end == null) {
      restored = restored.copyWith(
        clock: ClockEngine.resume(clock, turn: position.turn, now: now),
      );
    }
    return _timed(restored, now);
  }

  static FreeBoardState _fresh({
    required Position start,
    required Side? playerSide,
    required Side orientation,
    required ClockConfig? clock,
    required GameMode mode,
    required DateTime now,
  }) {
    return _timed(
      FreeBoardState(
        start: start,
        position: start,
        playerSide: playerSide,
        orientation: orientation,
        mode: mode,
        startedAt: now,
        turnStartedAt: GameRules.endOf(start) == null ? now : null,
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
