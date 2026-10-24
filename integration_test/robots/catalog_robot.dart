import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/catalog/view_models/catalog_cubit.dart';
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';
import 'home_robot.dart';

/// Telas do catálogo: as categorias e, na tela da categoria, os finais em
/// seções já abertas com as posições em grade.
class CatalogRobot {
  const CatalogRobot(this.$);

  final PatrolIntegrationTester $;

  // A lista passa de milhares de linhas (E1.06): a rolagem fixa do Patrol
  // (64 px, 15 vezes) não chega à seção do meio, e passos grandes pulam o
  // item. Rola até o item existir e então o traz para a tela.
  static const _step = 600.0;
  static const _maxDrags = 200;

  /// Rola a lista até [target] existir e o deixa visível.
  Future<void> _bring(Finder target) async {
    final list = find.byKey(CatalogKeys.positionList);
    await $(CatalogKeys.positionList).waitUntilVisible();
    if (target.evaluate().isEmpty) {
      // Parte do topo: o item pode estar acima do trecho que está na tela.
      final scrollable = $.tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)).first,
      );
      scrollable.position.jumpTo(0);
      await $.pump();
    }
    var drags = 0;
    while (target.evaluate().isEmpty && drags++ < _maxDrags) {
      await $.tester.drag(list, const Offset(0, -_step));
      await $.pump();
    }
    await $.tester.ensureVisible(target);
    await $.pumpAndSettle();
  }

  /// A partir da tela inicial.
  Future<void> open() async {
    await tapHomePath($, HomeKeys.catalogButton);
    await $(CatalogKeys.screen).waitUntilVisible();
    await $(CatalogKeys.category('basic')).waitUntilVisible();
  }

  Future<void> openCategory(String category) async {
    await $(CatalogKeys.category(category)).scrollTo().tap();
    await $(CatalogKeys.categoryScreen).waitUntilVisible();
  }

  /// Rola até a seção do final. Ela já vem aberta: não há tela à parte.
  Future<void> openSubcategory(String subcategory) async {
    await _bring(find.byKey(CatalogKeys.subcategory(subcategory)));
    await _expand(subcategory);
  }

  /// Toca no cabeçalho da seção: fecha a seção aberta ou abre a fechada.
  Future<void> toggleSubcategory(String subcategory) async {
    await _bring(find.byKey(CatalogKeys.subcategory(subcategory)));
    await $(CatalogKeys.subcategory(subcategory)).tap();
    await $.pumpAndSettle();
  }

  void expectPositionHidden(String id) {
    expect(find.byKey(CatalogKeys.position(id)), findsNothing);
  }

  /// Categoria com muitos finais abre só o primeiro (E1.06): abre a seção do
  /// [subcategory] se ela veio fechada.
  Future<void> _expand(String subcategory) async {
    final context = $.tester.element(find.byKey(CatalogKeys.positionList));
    final sections = context.read<CatalogCubit>().state.sections!;
    final section = sections.firstWhere((s) => s.subcategory == subcategory);
    if (section.expanded) return;
    await $(CatalogKeys.subcategory(subcategory)).tap();
    await $.pumpAndSettle();
  }

  /// Traz a posição [id] para a tela, abrindo a seção do final dela.
  Future<void> _reveal(String id) async {
    await openSubcategory(id.split('.')[1]);
    await _bring(find.byKey(CatalogKeys.position(id)));
  }

  /// Rola a lista até a posição e toca nela: abre a configuração da partida.
  Future<void> openPosition(String id) async {
    await _reveal(id);
    await $(CatalogKeys.position(id)).tap();
  }

  /// A posição tem a marca de objetivo cumprido.
  Future<void> expectFulfilled(String id) async {
    await _reveal(id);
    await $(CatalogKeys.fulfilled(id)).waitUntilVisible();
  }

  Future<void> expectNotFulfilled(String id) async {
    await _reveal(id);
    expect(find.byKey(CatalogKeys.fulfilled(id)), findsNothing);
  }

  Future<void> filter(GoalFilter filter) async {
    await $(CatalogKeys.filter(filter)).tap();
    await $.pumpAndSettle();
  }

  /// O nome de uma categoria como aparece na tela (a lista pode passar da
  /// altura do aparelho).
  Future<void> expectCategoryName(String category, String name) async {
    await $(CatalogKeys.categoryName(category)).scrollTo();
    expectText(
      $.tester
          .widget<Text>(find.byKey(CatalogKeys.categoryName(category)))
          .data,
      name,
    );
  }

  void expectCategoryHidden(String category) {
    expect(find.byKey(CatalogKeys.category(category)), findsNothing);
  }

  /// As posições que a tela da categoria mostra têm todas o objetivo [goal],
  /// e há pelo menos uma.
  void expectOnlyGoal(PositionGoal goal) {
    final context = $.tester.element(find.byKey(CatalogKeys.positionList));
    final positions = context.read<CatalogCubit>().state.visiblePositions!;
    expect(positions, isNotEmpty);
    expect(positions.map((p) => p.goal).toSet(), {goal});
  }

  /// A posição está na lista com o texto [text] (o mate, o objetivo).
  Future<void> expectPositionShows(String id, String text) async {
    await _reveal(id);
    expectTextIn(find.byKey(CatalogKeys.position(id)), text);
  }
}
