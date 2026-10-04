import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/home_robot.dart';
import '../robots/profile_robot.dart';

/// Fumaça da tela de perfil: tema escuro, árabe, segundo plano.
void main() {
  patrolTest('perfil em tema escuro', ($) async {
    final app = AppRobot($);
    final profile = ProfileRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await HomeRobot($).openSettings();
    await profile.open();

    await profile.expectVisible();
    app.expectBrightness(Brightness.dark);
  });

  patrolTest('perfil em árabe', ($) async {
    final app = AppRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await HomeRobot($).openSettings();
    await profile.expectSummary('لاعب · 1200');
    await profile.open();

    await profile.expectVisible();
    app.expectDirection(TextDirection.rtl);
    app.expectNoClippedText();
  });

  patrolTest('perfil volta do segundo plano com o que foi digitado', ($) async {
    final app = AppRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.enterRating('1850');

    await app.sendToBackgroundAndReturn();

    await profile.expectVisible();
    profile.expectFields(nickname: 'Ana', rating: '1850');
  });
}
