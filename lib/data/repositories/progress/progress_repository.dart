import '../../../domain/models/attempt.dart';

/// As partidas de treino terminadas.
abstract class ProgressRepository {
  Future<void> addAttempt(Attempt attempt);

  /// As partidas de uma posição, da mais recente para a mais antiga.
  Future<List<Attempt>> attemptsFor(String positionId);

  /// As posições em que o objetivo já foi cumprido alguma vez.
  Future<Set<String>> fulfilledPositions();

  /// As partidas de um desafio da Jornada, da mais recente para a mais
  /// antiga.
  Future<List<Attempt>> attemptsForChallenge(String challengeId);

  /// Os desafios da Jornada em que o objetivo já foi cumprido.
  Future<Set<String>> fulfilledChallenges();
}
