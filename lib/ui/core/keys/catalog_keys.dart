import 'package:flutter/widgets.dart';

import '../../../domain/models/endgame_position.dart';

abstract final class CatalogKeys {
  static const screen = Key('catalog.screen');
  static const categoryScreen = Key('catalog.category.screen');

  /// Opção do filtro por objetivo.
  static Key filter(GoalFilter filter) => Key('catalog.filter.${filter.code}');

  static Key category(String key) => Key('catalog.category.$key');
  static Key categoryName(String key) => Key('catalog.category.$key.name');

  /// O cabeçalho da seção de um final na tela da categoria: tocar abre ou
  /// fecha a seção.
  static Key subcategory(String key) => Key('catalog.subcategory.$key');
  static Key categoryDone(String key) => Key('catalog.category.$key.done');
  static Key position(String id) => Key('catalog.position.$id');

  /// A marca de objetivo cumprido de uma posição.
  static Key fulfilled(String id) => Key('catalog.position.$id.fulfilled');

  /// A lista da tela da categoria, com as seções e as posições.
  static const positionList = Key('catalog.positions');
  static const empty = Key('catalog.empty');
}
