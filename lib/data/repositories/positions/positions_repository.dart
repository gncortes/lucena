import '../../../domain/models/endgame_position.dart';

/// O catálogo de posições de finais.
abstract class PositionsRepository {
  /// As categorias, cada uma com as suas subcategorias e contagens.
  Future<List<CatalogCategory>> catalog();

  /// As posições de uma subcategoria, na ordem do catálogo.
  Future<List<EndgamePosition>> bySubcategory(String subcategory);

  /// Uma posição pelo id. Nula se não existe.
  Future<EndgamePosition?> byId(String id);
}
