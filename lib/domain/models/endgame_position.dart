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

/// Como uma posição do catálogo se liga a uma lição.
enum LessonRelation {
  /// É uma posição-base do tema da lição.
  base,

  /// Pela linha da tablebase, pode chegar a uma posição-base do tema.
  transposes;

  String get code => name;

  static LessonRelation? fromCode(String? code) => values.asNameMap()[code];
}

/// A ligação de uma posição com uma lição (gerada por
/// `tools/lesson_positions.py`, em `assets/positions/lesson_links.json`).
@freezed
abstract class LessonLink with _$LessonLink {
  const factory LessonLink({
    /// O id da lição de finais (`pawns.distantOpposition`).
    required String lessonId,
    required LessonRelation relation,

    /// Em que meio-lance da linha a posição chega ao tema (0 na base).
    @Default(0) int ply,
  }) = _LessonLink;
}

/// O filtro do catálogo: o objetivo e as lições marcadas. As lições combinam
/// em OU entre si e em E com o objetivo; sem lição marcada, só o objetivo
/// conta.
@freezed
abstract class CatalogFilter with _$CatalogFilter {
  const factory CatalogFilter({
    @Default(GoalFilter.all) GoalFilter goal,
    @Default(<String>{}) Set<String> lessons,
  }) = _CatalogFilter;

  const CatalogFilter._();

  /// Tem lição marcada?
  bool get byLesson => lessons.isNotEmpty;

  bool accepts(EndgamePosition position) =>
      goal.accepts(position.goal) &&
      (lessons.isEmpty ||
          position.links.any((l) => lessons.contains(l.lessonId)));

  /// A posição só transpõe para as lições marcadas (não é base de nenhuma
  /// delas)? Falso sem lição marcada.
  bool onlyTransposes(EndgamePosition position) {
    if (lessons.isEmpty) return false;
    final marked = position.links.where((l) => lessons.contains(l.lessonId));
    return marked.isNotEmpty &&
        marked.every((l) => l.relation == LessonRelation.transposes);
  }

  /// O filtro só com as lições que ainda existem ([known]).
  CatalogFilter retain(Iterable<String> known) {
    final kept = lessons.intersection(known.toSet());
    return kept.length == lessons.length ? this : copyWith(lessons: kept);
  }
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

    /// A seção por material (`KPvK`, `KPPvKP`...), o lado com mais peças
    /// primeiro. Nula nas posições sem material gravado.
    String? section,

    /// De 1 (mais fácil) a 3, pelo número de peças e pela distância da
    /// tablebase. Nula se o catálogo não informa.
    int? difficulty,

    /// As lições a que a posição se liga.
    @Default(<LessonLink>[]) List<LessonLink> links,
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

    /// As posições da subcategoria ligadas a alguma lição (para contar com o
    /// filtro de lição).
    @Default(<EndgamePosition>[]) List<EndgamePosition> lessonLinks,
  }) = _CatalogSubcategory;

  const CatalogSubcategory._();

  /// Quantas posições passam pelo filtro de objetivo.
  int count(GoalFilter filter) => switch (filter) {
    GoalFilter.all => winCount + drawCount,
    GoalFilter.win => winCount,
    GoalFilter.draw => drawCount,
  };

  /// Quantas posições passam pelo filtro inteiro. Com lição marcada, conta
  /// as ligações de cada posição ([lessonLinks]).
  int countFor(CatalogFilter filter) {
    if (!filter.byLesson) return count(filter.goal);
    return lessonLinks.where((p) => filter.accepts(p)).length;
  }
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

  int countFor(CatalogFilter filter) =>
      subcategories.fold(0, (total, sub) => total + sub.countFor(filter));
}
