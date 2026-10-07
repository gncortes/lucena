import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/endgame_difficulty.dart';

void main() {
  test('cada final na sua dificuldade', () {
    const expected = {
      'queen': SpeedrunCategory.beginner,
      'rook': SpeedrunCategory.beginner,
      'twoRooks': SpeedrunCategory.beginner,
      'pawnVsKing': SpeedrunCategory.intermediate,
      'twoBishopsVsKing': SpeedrunCategory.intermediate,
      'queenVsPawn': SpeedrunCategory.intermediate,
      'rookVsPawn': SpeedrunCategory.intermediate,
      'knightBishopVsKing': SpeedrunCategory.advanced,
      'queenVsRook': SpeedrunCategory.advanced,
      'rookPawnVsRook': SpeedrunCategory.advanced,
    };
    for (final MapEntry(key: sub, value: difficulty) in expected.entries) {
      expect(EndgameDifficulty.of(sub), difficulty, reason: sub);
    }
    expect(EndgameDifficulty.of('novo'), isNull);
  });

  test('o grupo vale pelo final mais fácil', () {
    const rookPawn = CatalogCategory(
      key: 'rookPawn',
      subcategories: [
        CatalogSubcategory(key: 'rookPawnVsRook', category: 'rookPawn'),
        CatalogSubcategory(key: 'rookVsPawn', category: 'rookPawn'),
      ],
    );
    expect(
      EndgameDifficulty.ofCategory(rookPawn),
      SpeedrunCategory.intermediate,
    );
  });
}
