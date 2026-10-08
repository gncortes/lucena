import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/endgames_robot.dart';
import '../robots/home_robot.dart';
import '../robots/settings_robot.dart';

const _lessonId = 'mates.bishopKnight.w';

/// Fumaça das aulas de finais: tema escuro, árabe, pseudo-idioma longo e
/// segundo plano.
void main() {
  Future<void> walkThrough(PatrolIntegrationTester $, AppRobot app) async {
    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    app.expectNoClippedText();
    await endgames.openLesson(_lessonId);
    app.expectNoClippedText();
    await endgames.openInfo();
    app.expectNoClippedText();
    await endgames.back();
    await endgames.openExercise(_lessonId, 'e01');
    app.expectNoClippedText();
    await endgames.back();
    await endgames.openSteps();
    app.expectNoClippedText();
  }

  patrolTest('aulas de finais em tema escuro', ($) async {
    final app = AppRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'));

    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    app.expectBrightness(Brightness.dark);
    await endgames.openLesson(_lessonId);
    app.expectBrightness(Brightness.dark);
  });

  patrolTest('aulas de finais em árabe, sem texto cortado', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('ar'));

    await walkThrough($, app);
    app.expectDirection(TextDirection.rtl);
  });

  patrolTest('aulas de finais no pseudo-idioma longo', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.backToHome();

    await walkThrough($, app);
  });

  patrolTest('exercício e lição voltam do segundo plano onde estavam', (
    $,
  ) async {
    final app = AppRobot($);
    final endgames = EndgamesRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);
    await endgames.openExercise(_lessonId, 'e06');
    await endgames.exerciseMove('d1g4');

    await app.sendToBackgroundAndReturn();
    await endgames.expectExercise(_lessonId, 'e06');
    endgames.expectExerciseBoard('1k6/8/1K6/2N5/6B1/8/8/8 w - - 2 2');

    await endgames.back();
    await endgames.openSteps();
    await endgames.nextStep();
    await app.sendToBackgroundAndReturn();
    await endgames.expectStep(_lessonId, 'whyWrong');
  });
}
