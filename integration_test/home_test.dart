import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/journey_robot.dart';

void main() {
  patrolTest('abrir o app mostra a tela inicial', ($) async {
    await AppRobot($).open();

    await HomeRobot($).expectVisible();
  });

  // O Patrol não gira o aparelho: este cenário vale de verdade quando o aparelho
  // já está deitado (emulador girado ou aparelho `orientation=landscape` no Test Lab).
  patrolTest('com o aparelho deitado o app continua em retrato', ($) async {
    final app = AppRobot($);
    await app.open();

    await HomeRobot($).expectVisible();
    app.expectPortrait();
  });

  patrolTest('sem internet o app abre e funciona normalmente', ($) async {
    final app = AppRobot($);
    await app.goOffline();
    addTearDown(app.goOnline);

    await app.open();

    await HomeRobot($).expectVisible();
  });

  patrolTest('"Continuar" abre o próximo desafio por cima da tela inicial, e '
      'voltar cai nela', ($) async {
    final home = HomeRobot($);
    final journey = JourneyRobot($);
    await AppRobot($).open(systemLocale: const Locale('en', 'US'));
    await home.expectVisible();

    await home.continueJourney();
    await journey.expectChallengeOpen();

    await journey.back();
    await home.expectVisible();
    journey.expectChallengeClosed();
  });
}
