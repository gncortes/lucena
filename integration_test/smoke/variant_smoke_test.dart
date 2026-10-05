import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/home_robot.dart';
import '../robots/variant.dart';

/// A variante da suíte (`E2E_VARIANT`) vale de verdade: sem este cenário, uma
/// suíte "em árabe" ou "em tema escuro" poderia passar rodando em inglês e no
/// claro.
void main() {
  patrolTest('a suíte roda no tema e no idioma da variante pedida', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).expectVisible();

    app.expectBrightness(
      e2eVariant == E2EVariant.dark ? Brightness.dark : Brightness.light,
    );
    app.expectDirection(
      e2eVariant == E2EVariant.arabic ? TextDirection.rtl : TextDirection.ltr,
    );
  });
}
