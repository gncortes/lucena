import 'package:lucena/data/repositories/speedrun/speedrun_repository.dart';
import 'package:lucena/domain/models/speedrun.dart';

import 'fake_progress_repository.dart';

/// Tentativas só na memória. As partidas vêm do [progress] (onde a partida as
/// grava), como no banco.
class FakeSpeedrunRepository implements SpeedrunRepository {
  FakeSpeedrunRepository(this.progress);

  final FakeProgressRepository progress;
  final _attempts = <SpeedrunAttempt>[];

  @override
  Future<SpeedrunAttempt> start(String speedrunId, DateTime at) async {
    final attempt = SpeedrunAttempt(
      id: _attempts.length + 1,
      speedrunId: speedrunId,
      startedAt: at,
    );
    _attempts.add(attempt);
    return attempt;
  }

  @override
  Future<void> abandon(int attemptId, DateTime at) async {
    final index = _attempts.indexWhere((attempt) => attempt.id == attemptId);
    _attempts[index] = _attempts[index].copyWith(abandonedAt: at);
  }

  @override
  Future<SpeedrunAttempt?> attempt(int attemptId) async {
    for (final attempt in _attempts) {
      if (attempt.id == attemptId) return _withGames(attempt);
    }
    return null;
  }

  @override
  Future<List<SpeedrunAttempt>> attempts(String speedrunId) async => [
    for (final attempt in _attempts)
      if (attempt.speedrunId == speedrunId) _withGames(attempt),
  ];

  SpeedrunAttempt _withGames(SpeedrunAttempt attempt) => attempt.copyWith(
    games: [
      for (final game in progress.attempts)
        if (game.speedrunAttemptId == attempt.id) game,
    ],
  );
}
