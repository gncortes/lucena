import '../../../domain/models/speedrun.dart';

/// As tentativas de speedrun. As partidas de cada uma são gravadas pela
/// partida, como as outras (`ProgressRepository`).
abstract class SpeedrunRepository {
  /// Começa uma tentativa de [speedrunId] no instante [at].
  Future<SpeedrunAttempt> start(String speedrunId, DateTime at);

  /// Desiste da tentativa: ela fica no histórico sem recorde.
  Future<void> abandon(int attemptId, DateTime at);

  /// Uma tentativa com as partidas dela. Nula se não existe.
  Future<SpeedrunAttempt?> attempt(int attemptId);

  /// As tentativas de [speedrunId], da mais antiga para a mais recente, com as
  /// partidas de cada uma.
  Future<List<SpeedrunAttempt>> attempts(String speedrunId);
}
