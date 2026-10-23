import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/use_cases/train_suggestion.dart';

void main() {
  const catalog = [
    CatalogCategory(
      key: 'queen',
      subcategories: [
        CatalogSubcategory(key: 'queen', category: 'queen', winCount: 2),
        CatalogSubcategory(key: 'queenVsPawn', category: 'queen', winCount: 3),
        CatalogSubcategory(key: 'queenVsRook', category: 'queen', winCount: 2),
        CatalogSubcategory(key: 'queenVsQueen', category: 'queen', winCount: 9),
      ],
    ),
  ];

  test('cada faixa começa pela dificuldade dela', () {
    expect(
      TrainSuggestion.of(RatingLevel.casual, catalog, {})?.subcategory.key,
      'queen',
    );
    expect(
      TrainSuggestion.of(RatingLevel.advanced, catalog, {})?.subcategory.key,
      'queenVsPawn',
    );
    expect(
      TrainSuggestion.of(RatingLevel.master, catalog, {})?.subcategory.key,
      'queenVsRook',
    );
  });

  test('conta as posições cumpridas do final', () {
    final suggestion = TrainSuggestion.of(RatingLevel.intermediate, catalog, {
      'queen.queenVsPawn.0001',
      'queen.queenVsPawn.0003',
      'queen.queen.0001',
    })!;

    expect(suggestion.subcategory.key, 'queenVsPawn');
    expect((suggestion.done, suggestion.total), (2, 3));
  });

  test('com o final todo cumprido, sobe de dificuldade', () {
    final suggestion = TrainSuggestion.of(RatingLevel.beginner, catalog, {
      'queen.queen.0001',
      'queen.queen.0002',
    });

    expect(suggestion?.subcategory.key, 'queenVsPawn');
  });

  test('sem nada por cumprir na faixa e acima, nulo', () {
    expect(
      TrainSuggestion.of(RatingLevel.expert, catalog, {
        'queen.queenVsRook.0001',
        'queen.queenVsRook.0002',
      }),
      isNull,
    );
  });
}
