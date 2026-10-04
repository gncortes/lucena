import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';

/// Fumaça: toda tela nova abre em tema escuro, em árabe, e volta do segundo plano.
void main() {
  patrolTest('tela inicial em tema escuro', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);

    await app.open();

    await home.expectVisible();
    home.expectMascot(dark: true);
  });

  // O árabe entra na T01; até lá o app cai no inglês e precisa abrir sem erro.
  patrolTest('tela inicial em árabe', ($) async {
    await AppRobot($).open(locale: const Locale('ar'));

    await HomeRobot($).expectVisible();
  });

  patrolTest('tela inicial volta do segundo plano', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    await app.open();
    await home.expectVisible();

    await app.sendToBackgroundAndReturn();

    await home.expectVisible();
  });
}
