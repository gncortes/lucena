import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:patrol/patrol.dart';

import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';

import 'catalog_robot.dart';
import 'game_setup_robot.dart';
import 'home_robot.dart';

/// A partida às cegas: abrir pelo atalho de "Todos os modos", o aviso do
/// microfone, o pedido do sistema e voltar a uma partida em curso.
class BlindRobot {
  const BlindRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial, abre o modo às cegas por "Todos os modos": com
  /// voz disponível, a entrada passa direto ao catálogo (ou, havendo partida
  /// guardada, à partida).
  Future<void> openEntry() async {
    await openFromAllModes($, 'blind');
    await $.pumpAndSettle();
  }

  /// Do catálogo às cegas até a partida nova: posição, configuração e a
  /// folha de introdução.
  Future<void> startNewGame() async {
    await openEntry();
    final catalog = CatalogRobot($);
    await $(CatalogKeys.screen).waitUntilVisible();
    await catalog.openCategory('basic');
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
    await $(GameSetupKeys.startButton).tap();
    await $(BlindKeys.screen).waitUntilVisible();
    await $(BlindKeys.start).waitUntilVisible();
    await $(BlindKeys.start).tap();
  }

  /// Começa a partida às cegas recusando o microfone: sem voz, o campo de
  /// digitar os lances é o jeito de jogar.
  Future<void> startWithoutMic() async {
    await startNewGame();
    await $(BlindKeys.mic).waitUntilVisible();
    await $(BlindKeys.mic).tap();
    await $(BlindKeys.micAllow).waitUntilVisible();
    await $(BlindKeys.micDeny).tap();
    await $(BlindKeys.screen).waitUntilVisible();
    await $(BlindKeys.typeField).waitUntilVisible();
  }

  /// Fecha o aviso do microfone com "Permitir": o sistema pede a permissão
  /// em seguida (diálogo nativo do aparelho). Concede se o pedido aparecer;
  /// se o aparelho já tinha a permissão, o pedido nem abre.
  Future<void> allowMic() async {
    await $(BlindKeys.mic).waitUntilVisible();
    await $(BlindKeys.mic).tap();
    await $(BlindKeys.micAllow).waitUntilVisible();
    await $(BlindKeys.micAllow).tap();
    final mobile = $.platform.mobile;
    if (await mobile.isPermissionDialogVisible(
      timeout: const Duration(seconds: 5),
    )) {
      await mobile.grantPermissionWhenInUse();
    }
    await $(BlindKeys.screen).waitUntilVisible();
  }

  /// A partida em curso está na tela (o jogo, não a entrada).
  Future<void> expectInGame() async {
    await $(BlindKeys.screen).waitUntilVisible();
    expect($(BlindKeys.typeField).exists || $(BlindKeys.mic).exists, isTrue);
  }
}
