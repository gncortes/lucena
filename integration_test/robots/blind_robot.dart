import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:patrol/patrol.dart';

import 'home_robot.dart';

/// A partida às cegas: abrir pelo atalho de "Todos os modos", o aviso do
/// microfone, o pedido do sistema e voltar a uma partida em curso.
class BlindRobot {
  const BlindRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial, abre a entrada do modo às cegas.
  Future<void> openEntry() async {
    await openFromAllModes($, 'blind');
    await $(BlindKeys.entry).waitUntilExists();
  }

  /// Começa a partida às cegas recusando o microfone: sem voz, o campo de
  /// digitar os lances é o jeito de jogar.
  Future<void> startWithoutMic() async {
    await openEntry();
    await $(BlindKeys.entry).tap();
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
