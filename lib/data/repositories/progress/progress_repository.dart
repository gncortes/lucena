import '../../../domain/models/attempt.dart';

/// As partidas jogadas nas posições do catálogo.
abstract class ProgressRepository {
  Future<void> addAttempt(Attempt attempt);

  /// As partidas de uma posição, da mais recente para a mais antiga.
  Future<List<Attempt>> attemptsFor(String positionId);

  /// As posições em que o objetivo já foi cumprido alguma vez.
  Future<Set<String>> fulfilledPositions();
}
