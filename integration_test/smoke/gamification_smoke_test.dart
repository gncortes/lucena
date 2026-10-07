import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import '../robots/app_robot.dart';
import '../robots/catalog_robot.dart';
import '../robots/free_board_robot.dart';
import '../robots/game_setup_robot.dart';
import '../robots/home_robot.dart';
import '../robots/progress_robot.dart';
import '../robots/settings_robot.dart';
import '../robots/tour_robot.dart';

/// Fumaça das telas novas (tour, tela inicial, conquistas, rating, ritmos e
/// personagens): tema escuro, árabe, pseudo-idioma longo e segundo plano.
void main() {
  Future<void> walkThrough(PatrolIntegrationTester $, AppRobot app) async {
    final tour = TourRobot($);
    final progress = ProgressRobot($);
    app.expectNoClippedText();
    // Os passos de aparência: tema e cor do app, depois o tabuleiro.
    await tour.next();
    await tour.expectStep(TourStep.theme);
    app.expectNoClippedText();
    await tour.next();
    await tour.expectStep(TourStep.board);
    app.expectNoClippedText();
    await tour.nextUntilLevel();
    app.expectNoClippedText();
    // No passo do nível não há "pular": começa com a faixa marcada.
    await tour.start();
    await HomeRobot($).expectVisible();
    app.expectNoClippedText();

    await progress.openAchievements();
    app.expectNoClippedText();
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await HomeRobot($).openSettings();
    await $(SettingsKeys.profileTile).tap();
    await $(ProfileKeys.ratingCard).scrollTo();
    app.expectNoClippedText();
    await $(BackButton).tap();
    await $(BackButton).tap();
    await $.pumpAndSettle();

    final catalog = CatalogRobot($);
    await catalog.open();
    await catalog.openCategory('basic');
    await catalog.openSubcategory('queen');
    await catalog.openPosition('basic.queen.0001');
    await GameSetupRobot($).expectVisible();
    await $(GameSetupKeys.paces).scrollTo();
    app.expectNoClippedText();
    await GameSetupRobot($).chooseLevel(1600);
    await GameSetupRobot($).start();
    await $(FreeBoardKeys.characterBar).waitUntilExists();
    app.expectNoClippedText();
  }

  patrolTest('telas novas em tema escuro', ($) async {
    final app = AppRobot($);
    await app.enableSystemDarkMode();
    addTearDown(app.disableSystemDarkMode);
    await app.open(systemLocale: const Locale('en', 'US'), tour: true);

    await TourRobot($).passVoice();
    app.expectBrightness(Brightness.dark);
    await walkThrough($, app);
    app.expectBrightness(Brightness.dark);
  });

  patrolTest('telas novas em árabe, sem texto cortado', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: const Locale('ar'), tour: true);

    await TourRobot($).passVoice();
    app.expectDirection(TextDirection.rtl);
    await walkThrough($, app);
  });

  patrolTest('telas novas no pseudo-idioma longo', ($) async {
    final app = AppRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    await HomeRobot($).openSettings();
    await settings.openLanguages();
    await settings.chooseLanguage(AppLanguage.pseudo);
    await settings.back();
    await TourRobot($).openFromSettings();
    await TourRobot($).passVoice();

    await walkThrough($, app);
  });

  patrolTest('tour, conquistas e partida com personagem voltam do segundo '
      'plano', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: const Locale('en', 'US'), tour: true);
    await TourRobot($).passVoice();
    await tour.next();
    await tour.chooseAccent(AppAccent.orange);
    await app.sendToBackgroundAndReturn();
    await tour.expectStep(TourStep.theme);
    tour.expectAccentValue('Orange');
    app.expectAccent(AppAccent.orange);
    await tour.skip();

    await ProgressRobot($).openAchievements();
    await app.sendToBackgroundAndReturn();
    await ProgressRobot($).expectLocked('first-fulfilled');
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await FreeBoardRobot($).openAt(
      'k7/8/8/8/8/8/8/4K2R w - - 0 1',
      opponent: 'maia',
      level: 1000,
      user: Side.white,
      goal: 'win',
    );
    await $(FreeBoardKeys.speechBubble).waitUntilVisible();
    await app.sendToBackgroundAndReturn();
    await $(FreeBoardKeys.speechBubble).waitUntilVisible();
  });
}
