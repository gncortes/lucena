import 'package:lucena/data/repositories/progress/progress_repository.dart';
import 'package:lucena/domain/models/attempt.dart';

/// Histórico só na memória, na ordem em que foi gravado.
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository([List<Attempt>? attempts]) : attempts = [...?attempts];

  final List<Attempt> attempts;

  @override
  Future<int> addAttempt(Attempt attempt) async {
    attempts.add(attempt);
    return attempts.length;
  }

  @override
  Future<List<Attempt>> allAttempts() async => [...attempts];

  // O id de uma partida é a posição dela na lista, a partir de 1.
  @override
  Future<Map<int, Attempt>> allAttemptsById() async => {
    for (final (index, attempt) in attempts.indexed) index + 1: attempt,
  };

  @override
  Future<Map<int, Attempt>> attemptsById(Iterable<int> ids) async => {
    for (final id in ids)
      if (id >= 1 && id <= attempts.length) id: attempts[id - 1],
  };

  @override
  Future<List<Attempt>> attemptsFor(String positionId) async => attempts
      .reversed
      .where((attempt) => attempt.positionId == positionId)
      .toList();

  @override
  Future<Set<String>> fulfilledPositions() async => {
    for (final attempt in attempts)
      if (attempt.fulfilled) attempt.positionId,
  };

  @override
  Future<List<Attempt>> attemptsForChallenge(String challengeId) async =>
      attempts.reversed
          .where((attempt) => attempt.challengeId == challengeId)
          .toList();

  @override
  Future<Set<String>> fulfilledChallenges() async => {
    for (final attempt in attempts)
      if (attempt.fulfilled && attempt.challengeId != null)
        attempt.challengeId!,
  };
}
