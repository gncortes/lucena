import '../../../domain/models/placement.dart';

/// O teste de nível (T52): o mapa de habilidades e o banco de perguntas (dos
/// assets), o teste em andamento e o resultado (gravados no aparelho).
abstract class PlacementRepository {
  Future<SkillMap> skills();

  Future<PlacementBank> bank();

  /// O teste começado e não terminado. Nulo: nenhum.
  Future<PlacementState?> ongoing();

  Future<void> saveOngoing(PlacementState state);

  Future<void> clearOngoing();

  /// O resultado do último teste. Nulo: o jogador nunca fez o teste.
  Future<PlacementResult?> result();

  Future<void> saveResult(PlacementResult result);
}
