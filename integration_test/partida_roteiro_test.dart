import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/custom_position_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_layout_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
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
    await $(BlindKeys.entry).waitUntilExists();
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

    await openFromAllModes($, 'blind');
    await $(BlindKeys.entry).waitUntilExists();
    await $(BlindKeys.entry).tap();
    await $(BlindKeys.mic).waitUntilVisible();
    await $(BlindKeys.mic).tap();
    await $(BlindKeys.micAllow).waitUntilVisible();
    await $(BlindKeys.micDeny).tap();
    await $(BlindKeys.screen).waitUntilVisible();
  });
}
