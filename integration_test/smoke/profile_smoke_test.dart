import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/home_robot.dart';
import '../robots/profile_robot.dart';

/// Fumaça da tela de perfil e do painel de faixas: tema escuro, árabe,
/// segundo plano.
void main() {
  patrolTest('perfil e painel de faixas em tema escuro', ($) async {
    final app = AppRobot($);
    final profile = ProfileRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    await HomeRobot($).openSettings();
    await profile.open();
    app.expectBrightness(Brightness.dark);

    await profile.chooseLevel(RatingLevel.expert);
    profile.expectFields(nickname: '', level: 'Expert');
  });

  patrolTest('perfil e painel de faixas em árabe', ($) async {
    final app = AppRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await HomeRobot($).openSettings();
    await profile.expectSummary('لاعب · هاوٍ');
    await profile.open();
    app.expectDirection(TextDirection.rtl);
    app.expectNoClippedText();

    await profile.openLevels();
    profile.expectInLevels('مبتدئ');
    profile.expectInLevels('أتعلم القواعد');
    app.expectNoClippedText();
  });

  patrolTest('perfil volta do segundo plano com o que foi editado', ($) async {
    final app = AppRobot($);
    final profile = ProfileRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await profile.open();
    await profile.enterNickname('Ana');
    await profile.chooseLevel(RatingLevel.advanced);

    await app.sendToBackgroundAndReturn();

    await profile.expectVisible();
    profile.expectFields(nickname: 'Ana', level: 'Advanced');
  });
}
