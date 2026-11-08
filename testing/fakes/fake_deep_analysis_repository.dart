import 'dart:async';

import 'package:lucena/data/repositories/deep_analysis/deep_analysis_repository.dart';
import 'package:lucena/domain/models/deep_analysis_job.dart';

/// A análise a fundo na memória: o teste controla o andamento.
class FakeDeepAnalysisRepository implements DeepAnalysisRepository {
  final requests = <DeepAnalysisRequest>[];
  final _jobs = <int, DeepAnalysisJob>{};
  final _changes = StreamController<DeepAnalysisJob>.broadcast(sync: true);

  @override
  DeepAnalysisJob start(DeepAnalysisRequest request) {
    final current = _jobs[request.gameId];
    if (current != null && current.running) return current;
    requests.add(request);
    final job = DeepAnalysisJob(
      gameId: request.gameId,
      weight: request.weight,
      status: DeepAnalysisStatus.running,
      progress: 0,
      startedAt: DateTime.utc(2026, 10, 6),
    );
    publish(job);
    return job;
  }

  void publish(DeepAnalysisJob job) {
    _jobs[job.gameId] = job;
    _changes.add(job);
  }

  @override
  DeepAnalysisJob? job(int gameId) => _jobs[gameId];

  @override
  Stream<DeepAnalysisJob> watch(int gameId) async* {
    if (_jobs[gameId] case final current?) yield current;
    yield* _changes.stream.where((job) => job.gameId == gameId);
  }
}
