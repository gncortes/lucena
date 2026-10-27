import '../models/endgame_position.dart';
import '../models/rating_level.dart';
import '../models/speedrun.dart';
import 'endgame_difficulty.dart';

/// O final sugerido pelo nível no cartão "Treinar finais" da tela inicial.
class TrainSuggestion {
  const TrainSuggestion({
    required this.subcategory,
    required this.done,
    required this.total,
  });

  final CatalogSubcategory subcategory;

  /// Posições do final com o objetivo já cumprido.
  final int done;
  final int total;

  /// O rating a partir do qual os finais [basics] deixam de ser sugeridos.
  static const basicsBelow = 1400;

  /// Os finais básicos da dificuldade intermediária.
  static const basics = {'pawnVsKing', 'twoBishopsVsKing'};

  /// O primeiro final da dificuldade do [level] (na ordem do catálogo) com
  /// posição por cumprir. Com todos cumpridos, sobe de dificuldade; com o
  /// catálogo todo cumprido, nulo.
  ///
  /// Com [rating] a partir de [basicsBelow], os finais básicos
  /// ([basics]: peão contra rei e dois bispos) não são sugeridos: quem joga
  /// nessa faixa já os domina.
  static TrainSuggestion? of(
    RatingLevel level,
    List<CatalogCategory> catalog,
    Set<String> fulfilled, {
    int? rating,
  }) {
    final skipBasics = rating != null && rating >= basicsBelow;
    final start = switch (level) {
      RatingLevel.beginner || RatingLevel.casual => SpeedrunCategory.beginner,
      RatingLevel.intermediate ||
      RatingLevel.advanced => SpeedrunCategory.intermediate,
      RatingLevel.expert || RatingLevel.master => SpeedrunCategory.advanced,
    };
    final tiers = [
      for (final tier in SpeedrunCategory.values)
        if (tier.index >= start.index) tier,
    ];
    for (final tier in tiers) {
      for (final category in catalog) {
        for (final sub in category.subcategories) {
          if (EndgameDifficulty.of(sub.key) != tier) continue;
          if (skipBasics && basics.contains(sub.key)) continue;
          final total = sub.count(GoalFilter.all);
          final prefix = '${sub.category}.${sub.key}.';
          final done = fulfilled.where((id) => id.startsWith(prefix)).length;
          if (total > 0 && done < total) {
            return TrainSuggestion(subcategory: sub, done: done, total: total);
          }
        }
      }
    }
    return null;
  }
}
