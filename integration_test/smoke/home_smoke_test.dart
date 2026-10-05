import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/home_robot.dart';

/// Fumaça da tela inicial: tema escuro, árabe, segundo plano e volta.
void main() {
  patrolTest('tela inicial em tema escuro', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);

    await app.open();

    await home.expectVisible();
    home.expectDark(dark: true);
  });

  patrolTest('tela inicial em árabe', ($) async {
    final app = AppRobot($);
    final home = HomeRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await home.expectVisible();
    app.expectDirection(TextDirection.rtl);
    home.expectSettingsButtonOnLeft();
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
