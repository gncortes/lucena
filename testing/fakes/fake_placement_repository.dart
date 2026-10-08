import 'package:lucena/data/repositories/placement/placement_repository.dart';
import 'package:lucena/domain/models/placement.dart';

/// O teste de nível em memória, com o mapa e o banco dados.
class FakePlacementRepository implements PlacementRepository {
  FakePlacementRepository({
    SkillMap? skills,
    PlacementBank? bank,
    this.saved,
    this.saveResultValue,
  }) : _skills = skills ?? SkillMap.empty,
       _bank = bank ?? PlacementBank(const []);

  final SkillMap _skills;
  final PlacementBank _bank;
  PlacementState? saved;
  PlacementResult? saveResultValue;

  @override
  Future<SkillMap> skills() async => _skills;

  @override
  Future<PlacementBank> bank() async => _bank;

  @override
  Future<PlacementState?> ongoing() async => saved;

  @override
  Future<void> saveOngoing(PlacementState state) async => saved = state;

  @override
  Future<void> clearOngoing() async => saved = null;

  @override
  Future<PlacementResult?> result() async => saveResultValue;

  @override
  Future<void> saveResult(PlacementResult result) async =>
      saveResultValue = result;
}
