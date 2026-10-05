import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';

void main() {
  patrolTest('abrir uma posição conhecida: FEN e lado corretos', ($) async {
    final catalog = CatalogRobot($);
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await catalog.open();
    await catalog.openCategory('pawn');
    await catalog.openSubcategory('pawnVsKing');

    // Posição de defesa em que jogam as pretas.
    await catalog.openPosition('pawn.pawnVsKing.0039');
    await setup.expectVisible();
    setup.expectPreviewOrientation(Side.black);
    await setup.start();

    await board.expectVisible();
    board.expectFen('8/8/4k3/8/8/5P1K/8/8 b - - 0 1');
    board.expectOrientation(Side.black);
    await board.expectMoves([]);
  });

  patrolTest('filtrar "defender": só posições de empate', ($) async {
    final catalog = CatalogRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await catalog.open();

    await catalog.filter(GoalFilter.draw);

    // Os mates básicos só têm posições de ganhar: a categoria some.
    catalog.expectCategoryHidden('basic');
    await catalog.openCategory('rookPawn');
    await catalog.openSubcategory('rookPawnVsRook');
    catalog.expectOnlyGoal(PositionGoal.draw);
  });

  patrolTest('rolar a maior categoria até o fim e abrir a última posição', (
    $,
  ) async {
    final catalog = CatalogRobot($);
    final setup = GameSetupRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await catalog.open();
    await catalog.openCategory('basic');

    await catalog.openPosition('basic.twoRooks.0006');

    await setup.expectVisible();
  });

  patrolTest('fechar a seção de um final esconde as posições dele; abrir de '
      'novo mostra', ($) async {
    final catalog = CatalogRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');

    await catalog.toggleSubcategory('queen');

    catalog.expectPositionHidden('basic.queen.0001');
    // A outra seção continua aberta.
    await catalog.expectPositionShows('basic.rook.0001', 'Win');

    await catalog.toggleSubcategory('queen');

    await catalog.expectPositionShows('basic.queen.0001', 'Win');
  });

  patrolTest('nomes das categorias traduzidos em espanhol e em árabe', (
    $,
  ) async {
    final app = AppRobot($);
    final catalog = CatalogRobot($);
    await app.open(systemLocale: const Locale('es', 'ES'));
    await catalog.open();
    catalog.expectCategoryName('basic', 'Mates básicos');
    catalog.expectCategoryName('pawn', 'Finales de peones');

    await app.open(systemLocale: const Locale('ar'));
    await catalog.open();
    catalog.expectCategoryName('basic', 'كش مات أساسي');
    catalog.expectCategoryName('queen', 'نهايات الوزير');
    app.expectDirection(TextDirection.rtl);
  });

  patrolTest('o objetivo aparece na lista e antes de jogar', ($) async {
    final catalog = CatalogRobot($);
    final setup = GameSetupRobot($);
    await AppRobot($).open(systemLocale: const Locale('pt', 'BR'));
    await catalog.open();
    await catalog.openCategory('pawn');
    await catalog.openSubcategory('pawnVsKing');

    await catalog.expectPositionShows('pawn.pawnVsKing.0041', 'Defender');
    await catalog.openPosition('pawn.pawnVsKing.0041');

    await setup.expectVisible();
    await setup.expectGoal('Defender');
  });
}
