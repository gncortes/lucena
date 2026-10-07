import '../models/endgame_position.dart';
import '../models/speedrun.dart';

/// A dificuldade de cada final, a mesma dos speedruns (iniciante,
/// intermediário, avançado): o treino avulso mostra um selo por grupo.
abstract final class EndgameDifficulty {
  /// A dificuldade do final [subcategory]. Nula se for desconhecido.
  static SpeedrunCategory? of(String subcategory) => switch (subcategory) {
    'queen' || 'rook' || 'twoRooks' => SpeedrunCategory.beginner,
    'pawnVsKing' ||
    'twoBishopsVsKing' ||
    'queenVsPawn' ||
    'rookVsPawn' => SpeedrunCategory.intermediate,
    'knightBishopVsKing' ||
    'queenVsRook' ||
    'rookPawnVsRook' => SpeedrunCategory.advanced,
    _ => null,
  };

  /// A dificuldade de um grupo: a do final mais fácil dele (é por onde se
  /// começa).
  static SpeedrunCategory? ofCategory(CatalogCategory category) {
    SpeedrunCategory? easiest;
    for (final sub in category.subcategories) {
      final difficulty = of(sub.key);
      if (difficulty == null) continue;
      if (easiest == null || difficulty.index < easiest.index) {
        easiest = difficulty;
      }
    }
    return easiest;
  }
}
