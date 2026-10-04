import 'package:lucena/data/repositories/training/training_repository.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';

/// Preferências do treino só na memória.
class FakeTrainingRepository implements TrainingRepository {
  FakeTrainingRepository({
    this.filter = GoalFilter.all,
    this.setup = const GameSetup(),
    this.draft,
  });

  GoalFilter filter;
  GameSetup setup;
  CustomPositionDraft? draft;
  final savedSetups = <GameSetup>[];

  @override
  Future<GoalFilter> loadCatalogFilter() async => filter;

  @override
  Future<void> saveCatalogFilter(GoalFilter filter) async =>
      this.filter = filter;

  @override
  Future<GameSetup> loadSetup() async => setup;

  @override
  Future<void> saveSetup(GameSetup setup) async {
    this.setup = setup;
    savedSetups.add(setup);
  }

  @override
  Future<CustomPositionDraft?> loadCustomDraft() async => draft;

  @override
  Future<void> saveCustomDraft(CustomPositionDraft draft) async =>
      this.draft = draft;
}
