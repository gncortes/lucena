import 'dart:async';

import 'package:dartchess/dartchess.dart';

import '../../../domain/models/deep_analysis_job.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/review_rules.dart';
import '../analysis/analysis_repository.dart';
import '../review/game_review_repository.dart';

/// A análise a fundo das partidas, com a vida do app (não da tela): sair da
/// tela não a interrompe. Guarda um trabalho por partida.
abstract class DeepAnalysisRepository {
  /// Começa a análise a fundo de [request.gameId]. Se já há uma rodando para
  /// a partida, devolve a que está rodando (não duplica).
  DeepAnalysisJob start(DeepAnalysisRequest request);

  /// O trabalho da partida (rodando, pronto ou com falha); nulo se nunca
  /// começou neste uso do app.
  DeepAnalysisJob? job(int gameId);

  /// O trabalho da partida: o estado de agora (se houver) e cada mudança.
  Stream<DeepAnalysisJob> watch(int gameId);
}

/// Faz a análise com a engine do app e grava a revisão no lugar da rápida.
class EngineDeepAnalysisRepository implements DeepAnalysisRepository {
  EngineDeepAnalysisRepository({
    required this._analysis,
    required this._reviews,
    required this._now,
  });

  final AnalysisRepository _analysis;
  final GameReviewRepository _reviews;
  final Now _now;

  final _jobs = <int, DeepAnalysisJob>{};
  final _changes = StreamController<DeepAnalysisJob>.broadcast();

  @override
  DeepAnalysisJob? job(int gameId) => _jobs[gameId];

  @override
  Stream<DeepAnalysisJob> watch(int gameId) async* {
    final changes = StreamController<DeepAnalysisJob>(sync: true);
    final subscription = _changes.stream
        .where((job) => job.gameId == gameId)
        .listen(changes.add);
    try {
      if (_jobs[gameId] case final current?) yield current;
      yield* changes.stream;
    } finally {
      await subscription.cancel();
      unawaited(changes.close());
    }
  }

  @override
  DeepAnalysisJob start(DeepAnalysisRequest request) {
    final current = _jobs[request.gameId];
    if (current != null && current.running) return current;
    final job = DeepAnalysisJob(
      gameId: request.gameId,
      weight: request.weight,
      status: DeepAnalysisStatus.running,
      progress: 0,
      startedAt: _now(),
    );
    _publish(job);
    unawaited(_run(request, job));
    return job;
  }

  void _publish(DeepAnalysisJob job) {
    _jobs[job.gameId] = job;
    if (!_changes.isClosed) _changes.add(job);
  }

  Future<void> _run(DeepAnalysisRequest request, DeepAnalysisJob first) async {
    try {
      final saved = await _reviews.load(request.gameId);
      if (saved != null &&
          saved.depth >= request.weight &&
          saved.moves.length == request.moves.length) {
        _publish(
          first.copyWith(
            status: DeepAnalysisStatus.done,
            progress: 1,
            finishedAt: _now(),
            review: saved,
          ),
        );
        return;
      }
      final positions = <Position>[request.start];
      for (final move in request.moves) {
        positions.add(positions.last.play(move));
      }
      final analyses = <List<EngineLine>?>[];
      for (final (index, position) in positions.indexed) {
        analyses.add(await _linesOf(position, request));
        _publish(
          _jobs[request.gameId]!.copyWith(
            progress: (index + 1) / positions.length,
          ),
        );
      }
      final review = ReviewRules.review(
        start: request.start,
        moves: request.moves,
        analyses: analyses,
        depth: request.weight,
      );
      await _reviews.save(request.gameId, review);
      _publish(
        _jobs[request.gameId]!.copyWith(
          status: DeepAnalysisStatus.done,
          progress: 1,
          finishedAt: _now(),
          review: review,
        ),
      );
    } on Object {
      _publish(
        _jobs[request.gameId]!.copyWith(
          status: DeepAnalysisStatus.failed,
          finishedAt: _now(),
        ),
      );
    }
  }

  /// As linhas da posição. Se a engine for interrompida por um pedido mais
  /// importante, pede de novo.
  Future<List<EngineLine>?> _linesOf(
    Position position,
    DeepAnalysisRequest request,
  ) async {
    if (position.isGameOver) return null;
    while (true) {
      try {
        final lines = await _analysis.analyse(
          position,
          depth: request.depth,
          time: request.time,
          lines: 2,
          preemptible: true,
        );
        return lines.isEmpty ? null : lines;
      } on AnalysisInterrupted {
        continue;
      }
    }
  }
}
