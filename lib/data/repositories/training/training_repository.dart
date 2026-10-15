import '../../../domain/models/endgame_position.dart';
import '../../../domain/models/game_setup.dart';

/// O rascunho da posição personalizada: o FEN e o objetivo escolhido.
typedef CustomPositionDraft = ({String fen, PositionGoal goal});

/// Preferências do treino: filtro do catálogo, última configuração de partida
/// e o rascunho da posição personalizada.
abstract class TrainingRepository {
  /// O filtro do catálogo (objetivo e lições). Quem só tinha o objetivo
  /// gravado (versão anterior) volta com ele e sem lição.
  Future<CatalogFilter> loadCatalogFilter();
  Future<void> saveCatalogFilter(CatalogFilter filter);

  Future<GameSetup> loadSetup();
  Future<void> saveSetup(GameSetup setup);

  /// Nulo se o jogador ainda não começou uma posição.
  Future<CustomPositionDraft?> loadCustomDraft();
  Future<void> saveCustomDraft(CustomPositionDraft draft);
}
