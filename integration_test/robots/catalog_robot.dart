import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/catalog/view_models/catalog_cubit.dart';
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:patrol/patrol.dart';

/// Telas do catálogo: categorias, subcategorias e posições.
class CatalogRobot {
  const CatalogRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial.
  Future<void> open() async {
    await $(HomeKeys.catalogButton).scrollTo().tap();
    await $(CatalogKeys.screen).waitUntilVisible();
    await $(CatalogKeys.category('basic')).waitUntilVisible();
  }

  Future<void> openCategory(String category) async {
    await $(CatalogKeys.category(category)).scrollTo().tap();
    await $(CatalogKeys.categoryScreen).waitUntilVisible();
  }

  Future<void> openSubcategory(String subcategory) async {
    await $(CatalogKeys.subcategory(subcategory)).scrollTo().tap();
    await $(CatalogKeys.subcategoryScreen).waitUntilVisible();
    await $(CatalogKeys.positionList).waitUntilVisible();
  }

  /// Rola a lista até a posição e toca nela.
  Future<void> openPosition(String id) async {
    await $(CatalogKeys.position(id))
        .scrollTo(view: find.byKey(CatalogKeys.positionList))
        .tap();
  }

  /// A posição tem a marca de objetivo cumprido.
  Future<void> expectFulfilled(String id) async {
    await $(CatalogKeys.position(id))
        .scrollTo(view: find.byKey(CatalogKeys.positionList));
    await $(CatalogKeys.fulfilled(id)).waitUntilVisible();
  }

  Future<void> filter(GoalFilter filter) async {
    await $(CatalogKeys.filter(filter)).tap();
    await $.pumpAndSettle();
  }

  /// O nome de uma categoria como aparece na tela.
  void expectCategoryName(String category, String name) {
    expect(
      $.tester
          .widget<Text>(find.byKey(CatalogKeys.categoryName(category)))
          .data,
      name,
    );
  }

  void expectCategoryHidden(String category) {
    expect(find.byKey(CatalogKeys.category(category)), findsNothing);
  }

  /// As posições que a lista mostra têm todas o objetivo [goal], e há pelo
  /// menos uma.
  void expectOnlyGoal(PositionGoal goal) {
    final context = $.tester.element(find.byKey(CatalogKeys.positionList));
    final positions = context.read<CatalogCubit>().state.visiblePositions!;
    expect(positions, isNotEmpty);
    expect(positions.map((p) => p.goal).toSet(), {goal});
  }

  /// A posição está na lista com o texto [text] (o mate, o objetivo).
  Future<void> expectPositionShows(String id, String text) async {
    await $(CatalogKeys.position(id))
        .scrollTo(view: find.byKey(CatalogKeys.positionList));
    expect(
      find.descendant(
        of: find.byKey(CatalogKeys.position(id)),
        matching: find.text(text),
      ),
      findsOneWidget,
    );
  }
}
