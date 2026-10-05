import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/maia_debug_robot.dart';

/// O Maia de verdade dentro do app, pela tela de depuração. A posição padrão
/// da tela é o final de torre contra rei das fixtures (`rook-mate`).
void main() {
  patrolTest('posição conhecida: o lance mais provável é o das fixtures', (
    $,
  ) async {
    final maia = MaiaDebugRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await maia.open();

    await maia.chooseLevel(1800);
    await maia.evaluate();

    await maia.expectResult();
    // test/fixtures/maia/reference.json, rook-mate@1800v1800: a1a4 com 0,3762.
    await maia.expectBest('a1a4', probability: '37.6%');
  });

  patrolTest('a mesma posição em 1000 e 2600 dá distribuições diferentes', (
    $,
  ) async {
    final maia = MaiaDebugRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await maia.open();

    await maia.chooseLevel(1000);
    await maia.evaluate();
    await maia.expectBest('a1a5', probability: '18.9%');
    final beginner = maia.shownMoves();

    await maia.chooseLevel(2600);
    await maia.evaluate();
    await maia.expectBest('a1d1');
    final master = maia.shownMoves();

    expect(beginner, hasLength(8));
    expect(master, isNot(beginner));
  });

  patrolTest('sem internet, o Maia responde igual', ($) async {
    final app = AppRobot($);
    final maia = MaiaDebugRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await app.goOffline();
    addTearDown(app.goOnline);
    await maia.open();

    await maia.chooseLevel(1800);
    await maia.evaluate();

    await maia.expectResult();
    await maia.expectBest('a1a4', probability: '37.6%');
  });

  patrolTest('FEN inválido: a tela avisa e não mostra resultado', ($) async {
    final maia = MaiaDebugRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await maia.open();

    await maia.enterFen('not a position');
    await maia.evaluate();

    await maia.expectInvalidPosition();
  });

  patrolTest('medir a velocidade: mostra o tempo típico por lance', ($) async {
    final maia = MaiaDebugRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await maia.open();

    await maia.measure();

    // Fora desta faixa, a medição quebrou (zero) ou o modelo travou.
    expect(await maia.measuredMedian(), inInclusiveRange(1, 5000));
    await maia.expectResult();
  });
}
