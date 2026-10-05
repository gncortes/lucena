import 'package:lucena/data/repositories/progress/progress_repository.dart';
import 'package:lucena/domain/models/attempt.dart';

/// Histórico só na memória, na ordem em que foi gravado.
class FakeProgressRepository implements ProgressRepository {
  FakeProgressRepository([List<Attempt>? attempts]) : attempts = [...?attempts];

  final List<Attempt> attempts;

  @override
  Future<void> addAttempt(Attempt attempt) async => attempts.add(attempt);

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
