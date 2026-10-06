import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/school/star_challenge_repository.dart';
import '../../../domain/models/star_challenge.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/star_challenge_rules.dart';

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
    this.lastMove,
    this.collected = 0,
    this.phase = ChallengePhase.ready,
    this.timeLeft = Duration.zero,
    this.best,
    this.earned = 0,
    this.newBest = false,
  });

  final ChallengePiece? piece;
  final ChallengeLevel? level;
  final String? fen;

  /// A estrela a pegar.
  final Square? star;
  final Move? lastMove;
  final int collected;
  final ChallengePhase phase;
  final Duration timeLeft;

  /// O melhor resultado anterior neste nível.
  final int? best;

  /// A nota (0 a 3) no fim.
  final int earned;
  final bool newBest;

  bool get ready => fen != null;
  bool get interactive => phase == ChallengePhase.running;

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
    Move? lastMove,
    bool clearLastMove = false,
    int? collected,
    ChallengePhase? phase,
    Duration? timeLeft,
    int? best,
    int? earned,
    bool? newBest,
  }) => StarChallengeState(
    piece: piece ?? this.piece,
    level: level ?? this.level,
    fen: fen ?? this.fen,
    star: clearStar ? null : star ?? this.star,
    lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
    collected: collected ?? this.collected,
    phase: phase ?? this.phase,
    timeLeft: timeLeft ?? this.timeLeft,
    best: best ?? this.best,
    earned: earned ?? this.earned,
    newBest: newBest ?? this.newBest,
  );
}

/// Um desafio das estrelas: a peça anda, a estrela muda de lugar, o relógio
/// corre. O tempo vem de [Now] e o tique de um [Timer]; os testes chamam
/// [tick] por conta própria.
class StarChallengeCubit extends Cubit<StarChallengeState> {
  StarChallengeCubit({
    required this._progress,
    required this._now,
    Random? random,
    this.tickEvery = const Duration(milliseconds: 100),
  }) : _random = random ?? Random(),
       super(const StarChallengeState());

  final StarChallengeRepository _progress;
  final Now _now;
  final Random _random;
  final Duration tickEvery;

  Board _board = Board.empty;
  Timer? _timer;
  DateTime? _startedAt;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;

  Future<void> load(ChallengePiece piece, ChallengeLevel level) async {
    final best = (await _progress.load()).bestOf(piece, level);
    if (isClosed) return;
    _board = StarChallengeRules.start(piece, level, _random);
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
    if (state.phase != ChallengePhase.ready) return;
    final square = StarChallengeRules.pieceSquare(_board);
    if (square == null) return;
    _startedAt = _now();
    _pausedTotal = Duration.zero;
    emit(
      state.copyWith(
        phase: ChallengePhase.running,
        star: StarChallengeRules.nextStar(
          _board,
          square,
          state.level!,
          _random,
        ),
        timeLeft: state.level!.duration,
      ),
    );
    _startTimer();
  }

  /// O relógio: quanto falta, e o fim quando chega a zero.
  void tick() {
    if (state.phase != ChallengePhase.running) return;
    final elapsed = _now().difference(_startedAt!) - _pausedTotal;
    final left = state.level!.duration - elapsed;
    if (left <= Duration.zero) {
      unawaited(_finish());
      return;
    }
    emit(state.copyWith(timeLeft: left));
  }

  /// O aluno moveu a peça.
  void play(Move move) {
    if (!state.interactive || move is! NormalMove) return;
    final moved = StarChallengeRules.move(_board, move.from, move.to);
    if (moved == null) return;
    final level = state.level!;
    final caught = move.to == state.star;
    _board = StarChallengeRules.respawnIfStuck(moved, _random);
    final square = StarChallengeRules.pieceSquare(_board)!;
    final star = caught
        ? StarChallengeRules.nextStar(_board, square, level, _random)
        : state.star;
    emit(
      state.copyWith(
        fen: StarChallengeRules.fen(_board),
        lastMove: move,
        collected: caught ? state.collected + 1 : state.collected,
        star: star,
        clearStar: star == null,
      ),
    );
  }

  /// Em segundo plano: o relógio para.
  void pause() {
    if (state.phase != ChallengePhase.running) return;
    _pausedAt = _now();
    _timer?.cancel();
    emit(state.copyWith(phase: ChallengePhase.paused));
  }

  void resume() {
    if (state.phase != ChallengePhase.paused) return;
    _pausedTotal += _now().difference(_pausedAt!);
    _pausedAt = null;
    emit(state.copyWith(phase: ChallengePhase.running));
    _startTimer();
  }

  /// De novo, com outro tabuleiro.
  Future<void> retry() async {
    _timer?.cancel();
    await load(state.piece!, state.level!);
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final piece = state.piece!;
    final level = state.level!;
    final collected = state.collected;
    final earned = StarChallengeRules.earned(level, collected);
    // Zero estrela não é recorde.
    final newBest = collected > 0 && collected > (state.best ?? 0);
    if (newBest) {
      final all = await _progress.load();
      await _progress.save(all.withBest(piece, level, collected));
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        phase: ChallengePhase.finished,
        timeLeft: Duration.zero,
        clearStar: true,
        earned: earned,
        newBest: newBest,
        best: newBest ? collected : state.best,
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

/// A lista dos desafios: os melhores resultados e o Viktor.
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
