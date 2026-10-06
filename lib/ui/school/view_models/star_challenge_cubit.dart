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
    this.starKind = StarKind.bronze,
    this.starTimeLeft = Duration.zero,
    this.starLifetime = Duration.zero,
    this.lastMove,
    this.collected = 0,
    this.points = 0,
    this.lastPoints = 0,
    this.phase = ChallengePhase.ready,
    this.timeLeft = Duration.zero,
    this.best,
    this.earned = 0,
    this.newBest = false,
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
  final ChallengePhase phase;
  final Duration timeLeft;

  /// O melhor resultado anterior neste nível (pontos).
  final int? best;

  /// A nota (0 a 3) no fim.
  final int earned;
  final bool newBest;

  bool get ready => fen != null;
  bool get interactive => phase == ChallengePhase.running;

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
    starKind: starKind ?? this.starKind,
    starTimeLeft: starTimeLeft ?? this.starTimeLeft,
    starLifetime: starLifetime ?? this.starLifetime,
    lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
    collected: collected ?? this.collected,
    points: points ?? this.points,
    lastPoints: lastPoints ?? this.lastPoints,
    phase: phase ?? this.phase,
    timeLeft: timeLeft ?? this.timeLeft,
    best: best ?? this.best,
    earned: earned ?? this.earned,
    newBest: newBest ?? this.newBest,
  );
}

/// Um desafio das estrelas: a peça anda, a estrela muda de lugar (e some no
/// prazo dela), o relógio corre. O tempo vem de [Now] e o tique de um
/// [Timer]; os testes chamam [tick] por conta própria.
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
  DateTime? _starExpiresAt;

  Future<void> load(ChallengePiece piece, ChallengeLevel level) async {
    final best = (await _progress.load()).bestOf(piece, level);
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
    if (state.phase != ChallengePhase.ready) return;
    final square = StarChallengeRules.pieceSquare(_board);
    if (square == null) return;
    _startedAt = _now();
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
    if (state.phase != ChallengePhase.running) return;
    final elapsed = _now().difference(_startedAt!) - _pausedTotal;
    final left = state.level!.duration - elapsed;
    if (left <= Duration.zero) {
      unawaited(_finish());
      return;
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
        ),
        square,
      ),
    );
  }

  /// Em segundo plano: o relógio (e o prazo da estrela) param.
  void pause() {
    if (state.phase != ChallengePhase.running) return;
    _pausedAt = _now();
    _timer?.cancel();
    emit(state.copyWith(phase: ChallengePhase.paused));
  }

  void resume() {
    if (state.phase != ChallengePhase.paused) return;
    final paused = _now().difference(_pausedAt!);
    _pausedTotal += paused;
    _starExpiresAt = _starExpiresAt?.add(paused);
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
    final points = state.points;
    final earned = StarChallengeRules.earned(level, points);
    // Zero ponto não é recorde.
    final newBest = points > 0 && points > (state.best ?? 0);
    if (newBest) {
      final all = await _progress.load();
      await _progress.save(all.withBest(piece, level, points));
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        phase: ChallengePhase.finished,
        timeLeft: Duration.zero,
        clearStar: true,
        earned: earned,
        newBest: newBest,
        best: newBest ? points : state.best,
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
