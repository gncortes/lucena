import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/core/keys/custom_position_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_layout_keys.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/blind_robot.dart';
import 'robots/catalog_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/custom_position_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_setup_robot.dart';
import 'robots/home_robot.dart';

/// Roteiro de validação da frente Partida (docs/tasks/T85-historias/partida.md)
/// que só vale no aparelho. Escrito sem rodar: a suíte local roda depois do
/// "tudo ok".
void main() {
  // Roteiro 3 (H-PAR-01): os atalhos de ferramentas abrem os destinos.
  patrolTest('todos os modos: atalhos de ferramentas abrem os destinos', (
    $,
  ) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await openFromAllModes($, 'freeBoard');
    await $(FreeBoardKeys.screen).waitUntilVisible();
    await $.platform.android.pressBack();

    await openFromAllModes($, 'custom');
    await $(CustomPositionKeys.screen).waitUntilVisible();
    await $.platform.android.pressBack();

    await openFromAllModes($, 'blind');
    // Com voz disponível, a entrada leva ao catálogo de posições.
    await $(CatalogKeys.screen).waitUntilVisible();
  });

  // Roteiro 4 (H-PAR-01): "Escolher os modos da home" abre o layout da home.
  patrolTest('todos os modos: o rodapé abre o layout da home', ($) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await openAllModes($);
    await $(AllModesKeys.chooseHome).tap();
    await $(HomeLayoutKeys.screen).waitUntilVisible();
  });

  // Roteiro 46 (H-PAR-09): o aviso do microfone vem antes do pedido do
  // sistema. O pedido em si (roteiro 48) usa o diálogo nativo do aparelho.
  patrolTest('às cegas: aviso do microfone antes do pedido do sistema', (
    $,
  ) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await BlindRobot($).startNewGame();
    await $(BlindKeys.mic).waitUntilVisible();
    await $(BlindKeys.mic).tap();
    await $(BlindKeys.micAllow).waitUntilVisible();
    await $(BlindKeys.micDeny).tap();
    await $(BlindKeys.screen).waitUntilVisible();
  });

  // Roteiro 48 (H-PAR-09): "Permitir" faz o sistema pedir a permissão; o
  // diálogo nativo é respondido pelo Patrol.
  patrolTest('às cegas: Permitir abre o pedido do sistema e a partida segue', (
    $,
  ) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();
    final blind = BlindRobot($);
    await blind.startNewGame();
    await blind.allowMic();
    await blind.expectInGame();
  });

  // Roteiro 45 (H-PAR-08): fechar à força no meio da partida às cegas e
  // reabrir volta a ela.
  patrolTest('às cegas: fechar à força e reabrir volta à partida', ($) async {
    final app = AppRobot($);
    final blind = BlindRobot($);
    await app.open();
    await HomeRobot($).expectVisible();
    await blind.startWithoutMic();

    // Com uma partida às cegas guardada, o app abre direto nela.
    await app.restart();
    await blind.expectInGame();
  });

  const pt = Locale('pt', 'BR');
  const mateInOne = '7k/8/5KQ1/8/8/8/8/8 w - - 0 1';

  Future<void> openSetup(PatrolIntegrationTester $) async {
    final catalog = CatalogRobot($);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
  }

  // Roteiro 13 (H-PAR-02): o nível escolhido sobrevive a fechar à força.
  patrolTest('nova partida: o nível escolhido sobrevive ao fechar à força', (
    $,
  ) async {
    final app = AppRobot($);
    final setup = GameSetupRobot($);
    await app.open(systemLocale: pt);
    await openSetup($);
    await setup.chooseOpponent(OpponentKind.maia);
    await setup.chooseLevel(1800);

    await app.restart();
    await openSetup($);

    await setup.expectLevel(1800);
  });

  // Roteiro 24 (H-PAR-04): o rascunho do editor sobrevive a fechar à força.
  patrolTest('editor: a posição montada continua depois de fechar à força', (
    $,
  ) async {
    final app = AppRobot($);
    final custom = CustomPositionRobot($);
    await app.open(systemLocale: pt);
    await custom.open();
    await custom.typeFen('8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');

    await app.restart();
    await custom.open();

    custom.expectFen('8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');
  });

  // Roteiro 26 (H-PAR-04): "Continuar" leva à Nova partida com a posição.
  patrolTest('editor: Continuar abre a Nova partida com a posição', ($) async {
    final custom = CustomPositionRobot($);
    await AppRobot($).open(systemLocale: pt);
    await custom.open();
    await custom.typeFen('8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');
    await custom.continueToSetup();

    await GameSetupRobot($).expectVisible();
  });

  // Roteiro 27 (H-PAR-05): com relógio, só o do turno corre.
  patrolTest('partida com relógio: os dois relógios aparecem', ($) async {
    final setup = GameSetupRobot($);
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: pt);
    await openSetup($);
    await setup.setTime('user', minutes: 5, increment: 3);
    await setup.setTime('opponent', minutes: 5, increment: 3);
    await setup.start();

    await board.expectVisible();
    await board.expectClock(Side.white, '5:00');
    await board.expectClock(Side.black, '5:00');
  });

  // Roteiro 36 (H-PAR-06): desistir leva à conclusão de derrota.
  patrolTest('desistir: a conclusão é de derrota, sem Nova partida na barra', (
    $,
  ) async {
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await AppRobot($).open(systemLocale: pt);
    await board.openAt(
      mateInOne,
      opponent: 'maia',
      level: 1600,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );
    await board.resign();

    await conclusion.waitConclusion();
    await conclusion.expectAction(ConclusionAction.newGame);
    expect(find.byKey(ConclusionKeys.appBarNewGame), findsNothing);
  });

  // Roteiro 62 (H-PAR-12): fechar à força na conclusão reabre nela.
  patrolTest('conclusão: fechar à força reabre na conclusão', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    final conclusion = ConclusionRobot($);
    await app.open(systemLocale: pt);
    await board.openAt(
      mateInOne,
      opponent: 'maia',
      level: 1600,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );
    await board.move('g6', 'g7');
    await conclusion.seeResult();
    await conclusion.waitConclusion();

    await app.restart();

    await conclusion.waitConclusion();
  });
}
