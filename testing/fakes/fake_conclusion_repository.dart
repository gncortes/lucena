import 'package:lucena/data/repositories/conclusion/conclusion_repository.dart';

/// A conclusão aberta, em memória.
class FakeConclusionRepository implements ConclusionRepository {
  FakeConclusionRepository([this.gameId]);

  int? gameId;

  @override
  Future<int?> pending() async => gameId;

  @override
  Future<void> open(int gameId) async => this.gameId = gameId;

  @override
  Future<void> clear() async => gameId = null;
}
