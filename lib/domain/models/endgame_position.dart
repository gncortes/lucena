import 'package:freezed_annotation/freezed_annotation.dart';

part 'endgame_position.freezed.dart';

/// O que o jogador precisa fazer na posição.
enum PositionGoal {
  /// Só a vitória conta.
  win,

  /// Empatar (ou ganhar) conta: é segurar a posição.
  draw;

  /// Valor no catálogo e nas preferências.
  String get code => name;

  static PositionGoal? fromCode(String? code) => values.asNameMap()[code];
}

/// Filtro do catálogo por objetivo.
enum GoalFilter {
  all,
  win,
  draw;

  static const fallback = GoalFilter.all;

  bool accepts(PositionGoal goal) => switch (this) {
    GoalFilter.all => true,
    GoalFilter.win => goal == PositionGoal.win,
    GoalFilter.draw => goal == PositionGoal.draw,
  };

  /// Valor gravado nas preferências.
  String get code => name;

  static GoalFilter fromCode(String? code) =>
      values.asNameMap()[code] ?? fallback;
}

/// Uma posição de final do catálogo. O lado do jogador é o lado que joga no
/// FEN.
@freezed
abstract class EndgamePosition with _$EndgamePosition {
  const factory EndgamePosition({
    /// `categoria.subcategoria.NNNN`, estável entre versões do catálogo.
    required String id,
    required String category,
    required String subcategory,
    required String fen,
    required PositionGoal goal,

    /// Mate em quantos lances, quando a fonte informa.
    int? mateIn,

    /// Conferida na tablebase do Lichess.
    @Default(false) bool verified,
  }) = _EndgamePosition;

  const EndgamePosition._();

  /// O número da posição dentro da subcategoria (1, 2, 3...).
  int get number => int.parse(id.split('.').last);
}

/// Uma subcategoria do catálogo e quantas posições ela tem de cada objetivo.
@freezed
abstract class CatalogSubcategory with _$CatalogSubcategory {
  const factory CatalogSubcategory({
    required String key,
    required String category,
    @Default(0) int winCount,
    @Default(0) int drawCount,
  }) = _CatalogSubcategory;

  const CatalogSubcategory._();

  /// Quantas posições passam pelo filtro.
  int count(GoalFilter filter) => switch (filter) {
    GoalFilter.all => winCount + drawCount,
    GoalFilter.win => winCount,
    GoalFilter.draw => drawCount,
  };
}

/// Uma categoria do catálogo, com as subcategorias na ordem da fonte.
@freezed
abstract class CatalogCategory with _$CatalogCategory {
  const factory CatalogCategory({
    required String key,
    required List<CatalogSubcategory> subcategories,
  }) = _CatalogCategory;

  const CatalogCategory._();

  int count(GoalFilter filter) =>
      subcategories.fold(0, (total, sub) => total + sub.count(filter));
}
