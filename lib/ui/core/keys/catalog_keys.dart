import 'package:flutter/widgets.dart';

import '../../../domain/models/endgame_position.dart';

abstract final class CatalogKeys {
  static const screen = Key('catalog.screen');
  static const categoryScreen = Key('catalog.category.screen');
  static const subcategoryScreen = Key('catalog.subcategory.screen');

  /// Opção do filtro por objetivo.
  static Key filter(GoalFilter filter) => Key('catalog.filter.${filter.code}');

  static Key category(String key) => Key('catalog.category.$key');
  static Key categoryName(String key) => Key('catalog.category.$key.name');
  static Key subcategory(String key) => Key('catalog.subcategory.$key');
  static Key categoryDone(String key) => Key('catalog.category.$key.done');
  static Key position(String id) => Key('catalog.position.$id');

  /// A marca de objetivo cumprido de uma posição.
  static Key fulfilled(String id) => Key('catalog.position.$id.fulfilled');

  static const positionList = Key('catalog.positions');
  static const empty = Key('catalog.empty');
}
