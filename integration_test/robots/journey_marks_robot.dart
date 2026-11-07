import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:patrol/patrol.dart';

/// As marcas das jornadas gravadas do QA da R5 (`docs/tasks/E1.19-qa-r5.md`,
/// "Jornadas"). Cada marca sai no logcat como `JORNADA {json}`; o gravador do
/// computador (`tools/jornadas_r5.sh` → `tools/jornada_gravar.py`) lê o logcat
/// ao vivo e:
/// - `passo`: vira a legenda do vídeo a partir daquele instante;
/// - `painel`: legenda marcada como ação do painel (para casar com o vídeo
///   do painel pelo horário);
/// - `notificacao`: posta a notificação por adb com o mesmo título e texto
///   que a Function manda (o FCM não é emulado);
/// - `link`: abre o link por `adb shell am start -a VIEW -d <link>`.
class JourneyMarksRobot {
  JourneyMarksRobot(this.$);

  final PatrolIntegrationTester $;

  void _mark(Map<String, Object?> mark) =>
      debugPrint('JORNADA ${jsonEncode(mark)}');

  /// Legenda do passo que começa agora.
  Future<void> step(String caption) async {
    _mark({'passo': caption});
    await hold(800);
  }

  /// Ação que, no vídeo lado a lado, é do painel (aqui feita pela mesma
  /// Function que o painel chama).
  Future<void> panel(String caption) async {
    _mark({'painel': caption});
    await hold(400);
  }

  /// Pede ao gravador a notificação do push e a mostra na gaveta. Quem chamou
  /// entrega depois o toque ao app (o mesmo `data` da Function).
  Future<void> notification(String title, String text) async {
    _mark({
      'notificacao': {'titulo': title, 'texto': text},
    });
    await hold(2500);
    await $.platform.mobile.openNotifications();
    await hold(3000);
    await $.platform.mobile.closeNotifications();
    await hold(500);
  }

  /// Pede ao gravador para abrir [link] como o Android abre um link de fora.
  void openLink(String link) => _mark({'link': link});

  /// Deixa a tela parada [ms] para o vídeo (o app segue trabalhando).
  Future<void> hold([int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await $.tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await $.pump(const Duration(milliseconds: 40));
    }
  }
}
