import '../../../domain/use_cases/clock_engine.dart';

import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/school/star_challenge_repository.dart';
import '../../../domain/models/star_challenge.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/star_challenge_rules.dart';
import '../../core/sound/game_sounds.dart';
import '../../../domain/models/game_sound.dart';
import '../../../domain/models/haptic_event.dart';
import '../../core/sound/game_haptics.dart';

enum ChallengePhase {
  /// O tabuleiro montado, esperando o "vai".
  ready,
  running,

  /// Em segundo plano: o relógio para.
  paused,
  finished,
}

class StarChallengeState {
  const StarChallengeState({
    this.piece,
    this.level,
    this.fen,
    this.star,
    this.starKind = StarKind.bronze,
    this.starTimeLeft = Duration.zero,
    this.starLifetime = Duration.zero,
    this.lastMove,
    this.collected = 0,
    this.points = 0,
    this.lastPoints = 0,
    this.byKind = const {},
    this.phase = ChallengePhase.ready,
    this.timeLeft = Duration.zero,
    this.best,
    this.earned = 0,
    this.newBest = false,
    this.saving = false,
    this.saveError = false,
  });

  final ChallengePiece? piece;
  final ChallengeLevel? level;
  final String? fen;

  /// A estrela a pegar, o tipo dela e quanto tempo ainda fica na tela.
  final Square? star;
  final StarKind starKind;
  final Duration starTimeLeft;
  final Duration starLifetime;
  final Move? lastMove;

  /// Estrelas pegas e os pontos delas; [lastPoints] é o que a última valeu.
  final int collected;
  final int points;
  final int lastPoints;

  /// Quantas estrelas de cada cor foram pegas.
  final Map<StarKind, int> byKind;

  /// Quantas estrelas desta cor foram pegas.
  int countOf(StarKind kind) => byKind[kind] ?? 0;
  final ChallengePhase phase;
  final Duration timeLeft;

  /// O melhor resultado anterior neste nível (pontos).
  final int? best;

  /// A nota (0 a 3) no fim.
  final int earned;
  final bool newBest;
  final bool saving, saveError;

  bool get ready => fen != null;
  bool get interactive =>
      phase == ChallengePhase.running && !saving && !saveError;

  /// A estrela está para sumir (o último segundo): pisca.
  bool get starBlinking =>
      star != null && starTimeLeft <= const Duration(milliseconds: 1200);

  /// Quanto do tempo já passou (0 a 1).
  double get elapsedFraction {
    final total = level?.duration;
    if (total == null || total == Duration.zero) return 0;
    return 1 - timeLeft.inMilliseconds / total.inMilliseconds;
  }

  StarChallengeState copyWith({
    ChallengePiece? piece,
    ChallengeLevel? level,
    String? fen,
    Square? star,
    bool clearStar = false,
    StarKind? starKind,
    Duration? starTimeLeft,
    Duration? starLifetime,
    Move? lastMove,
    bool clearLastMove = false,
    int? collected,
    int? points,
    int? lastPoints,
    Map<StarKind, int>? byKind,
    ChallengePhase? phase,
    Duration? timeLeft,
    int? best,
    int? earned,
    bool? newBest,
    bool? saving,
    bool? saveError,
  }) => StarChallengeState(
    piece: piece ?? this.piece,
    level: level ?? this.level,
    fen: fen ?? this.fen,
    star: clearStar ? null : star ?? this.star,
    starKind: starKind ?? this.starKind,
    starTimeLeft: starTimeLeft ?? this.starTimeLeft,
    starLifetime: starLifetime ?? this.starLifetime,
    lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
    collected: collected ?? this.collected,
    points: points ?? this.points,
    lastPoints: lastPoints ?? this.lastPoints,
    byKind: byKind ?? this.byKind,
    phase: phase ?? this.phase,
    timeLeft: timeLeft ?? this.timeLeft,
    best: best ?? this.best,
    earned: earned ?? this.earned,
    newBest: newBest ?? this.newBest,
    saving: saving ?? this.saving,
    saveError: saveError ?? this.saveError,
  );
}

/// Um desafio das estrelas: a peça anda, a estrela muda de lugar (e some no
/// prazo dela), o relógio corre. O tempo vem de [Now] e o tique de um
/// [Timer]; os testes chamam [tick] por conta própria.
class StarChallengeCubit extends Cubit<StarChallengeState> {
  StarChallengeCubit({
    required this._progress,
    required this._now,
    this._sounds,
    this._haptics,
    Random? random,
    this.tickEvery = const Duration(milliseconds: 100),
  }) : _random = random ?? Random(),
       super(const StarChallengeState());

  final StarChallengeRepository _progress;
  final Now _now;
  final Random _random;

  /// Com este tempo ou menos, o relógio avisa que está acabando.
  static const lowTime = ClockEngine.lowTime;

  // Os sons do jogo; nulo: o desafio fica mudo.
  final GameSounds? _sounds;

  // A vibração; nula: sem retorno tátil.
  final GameHaptics? _haptics;

  // O aviso de pouco tempo toca uma vez por desafio.
  var _lowTimeWarned = false;
  final Duration tickEvery;

  Board _board = Board.empty;
  Timer? _timer;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;
  DateTime? _starExpiresAt;
  bool _finishing = false;
  StarChallengeRun? _pendingRun;
  StarChallengeState? _finishSnapshot;

  Future<void> load(ChallengePiece piece, ChallengeLevel level) async {
    if (_pendingRun != null) return;
    final best = (await _progress.load()).bestOf(piece, level);
    if (isClosed) return;
    // Fechado à força, o app reabre no Pronto deste desafio.
    await _progress.setOpen(OpenStarChallenge(piece, level));
    if (isClosed) return;
    _board = StarChallengeRules.start(piece, level, _random);
    _starExpiresAt = null;
    emit(
      StarChallengeState(
        piece: piece,
        level: level,
        fen: StarChallengeRules.fen(_board),
        best: best,
        timeLeft: level.duration,
      ),
    );
  }

  /// "Vai": a primeira estrela aparece e o relógio começa.
  void start() {
    if (_pendingRun != null) return;
    if (state.phase != ChallengePhase.ready) return;
    final square = StarChallengeRules.pieceSquare(_board);
    if (square == null) return;
    _startedAt = _now();
    _lowTimeWarned = false;
    _pausedTotal = Duration.zero;
    emit(
      _spawn(
        state.copyWith(
          phase: ChallengePhase.running,
          timeLeft: state.level!.duration,
        ),
        square,
      ),
    );
    _startTimer();
  }

  /// Acende a próxima estrela a partir de [square]: casa, tipo e prazo.
  StarChallengeState _spawn(StarChallengeState base, Square square) {
    final level = base.level!;
    final star = StarChallengeRules.nextStar(_board, square, level, _random);
    if (star == null) {
      _starExpiresAt = null;
      return base.copyWith(clearStar: true);
    }
    final kind = StarChallengeRules.pickKind(_random);
    final lifetime = level.starLifetime(kind);
    _starExpiresAt = _now().add(lifetime);
    return base.copyWith(
      star: star,
      starKind: kind,
      starLifetime: lifetime,
      starTimeLeft: lifetime,
    );
  }

  /// O relógio: quanto falta, o fim quando chega a zero, e a estrela que
  /// some no prazo (outra acende, sem ponto).
  void tick() {
    if (!state.interactive) return;
    final elapsed = _now().difference(_startedAt!) - _pausedTotal;
    final left = state.level!.duration - elapsed;
    if (left <= Duration.zero) {
      unawaited(_finish());
      return;
    }
    if (left <= lowTime && !_lowTimeWarned) {
      _lowTimeWarned = true;
      unawaited(_sounds?.play(GameSound.lowTime));
    }
    final expiresAt = _starExpiresAt;
    final starLeft = expiresAt == null
        ? Duration.zero
        : expiresAt.difference(_now());
    if (state.star != null && starLeft <= Duration.zero) {
      final square = StarChallengeRules.pieceSquare(_board)!;
      emit(_spawn(state.copyWith(timeLeft: left), square));
      return;
    }
    emit(state.copyWith(timeLeft: left, starTimeLeft: starLeft));
  }

  /// O aluno moveu a peça.
  void play(Move move) {
    if (!state.interactive || move is! NormalMove) return;
    final moved = StarChallengeRules.move(_board, move.from, move.to);
    if (moved == null) return;
    final caught = move.to == state.star;
    unawaited(_sounds?.play(caught ? GameSound.capture : GameSound.move));
    unawaited(_haptics?.play(caught ? HapticEvent.capture : HapticEvent.move));
    _board = StarChallengeRules.respawnIfStuck(moved, _random);
    final square = StarChallengeRules.pieceSquare(_board)!;
    final after = state.copyWith(
      fen: StarChallengeRules.fen(_board),
      lastMove: move,
    );
    if (!caught) {
      emit(after);
      return;
    }
    final worth = state.starKind.points;
    emit(
      _spawn(
        after.copyWith(
          collected: state.collected + 1,
          points: state.points + worth,
          lastPoints: worth,
          byKind: {
            ...state.byKind,
            state.starKind: state.countOf(state.starKind) + 1,
          },
        ),
        square,
      ),
    );
  }

  /// Em segundo plano: o relógio (e o prazo da estrela) param.
  void pause() {
    if (!state.interactive) return;
    _pausedAt = _now();
    _timer?.cancel();
    emit(state.copyWith(phase: ChallengePhase.paused));
  }

  void resume() {
    if (_pendingRun != null) return;
    if (state.phase != ChallengePhase.paused) return;
    final paused = _now().difference(_pausedAt!);
    _pausedTotal += paused;
    _starExpiresAt = _starExpiresAt?.add(paused);
    _pausedAt = null;
    emit(state.copyWith(phase: ChallengePhase.running));
    _startTimer();
  }

  /// O aluno saiu da tela: o app não reabre mais no desafio.
  Future<void> leave() => _progress.setOpen(null);

  /// De novo, com outro tabuleiro.
  Future<void> retry() async {
    if (_pendingRun != null) return;
    _timer?.cancel();
    await load(state.piece!, state.level!);
  }

  Future<void> _finish() async {
    if (_pendingRun != null || !state.interactive) return;
    _timer?.cancel();
    _pendingRun = StarChallengeRun(
      piece: state.piece!,
      level: state.level!,
      points: state.points,
      at: _now(),
    );
    _finishSnapshot = state.copyWith(timeLeft: Duration.zero);
    await _saveFinish();
  }

  /// Retries the same finished round, preserving its original points and date.
  Future<void> retryFinish() async {
    if (!state.saveError || state.saving) return;
    await _saveFinish();
  }

  Future<void> _saveFinish() async {
    final run = _pendingRun;
    final snapshot = _finishSnapshot;
    if (_finishing || run == null || snapshot == null || isClosed) return;
    _finishing = true;
    emit(snapshot.copyWith(saving: true, saveError: false));
    final earned = StarChallengeRules.earned(run.level, run.points);
    // Zero ponto não é recorde.
    final newBest = run.points > 0 && run.points > (snapshot.best ?? 0);
    try {
      await _progress.addRun(
        piece: run.piece,
        level: run.level,
        points: run.points,
        at: run.at,
      );
    } catch (_) {
      if (!isClosed) emit(snapshot.copyWith(saving: false, saveError: true));
      return;
    } finally {
      _finishing = false;
    }
    _pendingRun = null;
    _finishSnapshot = null;
    if (isClosed) return;
    emit(
      snapshot.copyWith(
        phase: ChallengePhase.finished,
        timeLeft: Duration.zero,
        clearStar: true,
        earned: earned,
        newBest: newBest,
        best: newBest ? run.points : snapshot.best,
        saving: false,
        saveError: false,
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(tickEvery, (_) => tick());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}

/// A lista dos desafios: os melhores resultados.
class StarChallengesState {
  const StarChallengesState({
    this.ready = false,
    this.progress = const StarChallengeProgress(),
  });

  final bool ready;
  final StarChallengeProgress progress;
}

class StarChallengesCubit extends Cubit<StarChallengesState> {
  StarChallengesCubit({required this._progress})
    : super(const StarChallengesState());

  final StarChallengeRepository _progress;

  Future<void> load() async {
    final progress = await _progress.load();
    if (isClosed) return;
    emit(StarChallengesState(ready: true, progress: progress));
  }
}
