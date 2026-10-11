import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/journey_robot.dart';
import 'robots/settings_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/variant.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('primeira abertura: tour, escolher 1400 e a Jornada começa no '
      '1400', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.passVoice();

    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start();

    await HomeRobot($).expectVisible();
    await $(HomeKeys.whereTitle).waitUntilVisible();
    expectText(
      $.tester.widget<Text>(find.byKey(HomeKeys.whereTitle)).data,
      'Percival',
    );
    final journey = JourneyRobot($);
    await journey.open();
    await journey.expectCurrent('Percival');
    await journey.expectUnlocked('1000');
    await journey.expectLocked('1600');
  });

  patrolTest('o nome dado no tour aparece na tela inicial e continua ao '
      'reabrir', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    final home = HomeRobot($);
    await app.open(systemLocale: _english, tour: true);
    await tour.passVoice();
    await tour.enterName('Gabriel');

    // Fechar à força no meio do tour não perde o nome.
    await tour.next();
    await app.restart();
    await tour.expectStep(TourStep.theme);
    await tour.back();
    await tour.expectName('Gabriel');

    await tour.skip();
    await home.expectVisible();
    await home.expectHello('Hi, Gabriel');

    await app.restart();
    await home.expectVisible();
    await home.expectHello('Hi, Gabriel');
  });

  patrolTest('pular o tour: ao reabrir ele não aparece de novo', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);
    await tour.passVoice();
    await tour.skip();
    await HomeRobot($).expectVisible();

    await app.restart();
    await HomeRobot($).expectVisible();
    await $.pumpAndSettle();
    tour.expectNotOpen();
  });

  patrolTest('rever o tour em Configurações', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english);
    tour.expectNotOpen();
    await HomeRobot($).openSettings();
    await tour.openFromSettings();
    await tour.passVoice();
    await tour.next();
    await tour.expectStep(TourStep.theme);
    await tour.skip();
    await HomeRobot($).expectVisible();
  });

  patrolTest('fechar à força no meio do tour: reabre no mesmo passo', (
    $,
  ) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);
    await TourRobot($).passVoice();
    await tour.next();
    await tour.next();
    await tour.next();
    await tour.expectStep(TourStep.sound);

    await app.restart();
    await tour.expectStep(TourStep.sound);
  });

  patrolTest('primeira abertura: tema escuro, cor rosa e tabuleiro verde no '
      'tour valem no app e continuam ao reabrir', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: _english, tour: true);
    await TourRobot($).passVoice();
    await tour.next();
    await tour.expectStep(TourStep.theme);

    // A escolha vale na hora, no próprio tour.
    await tour.chooseThemeMode(AppThemeMode.dark);
    app.expectBrightness(Brightness.dark);
    await tour.chooseAccent(AppAccent.pink);
    tour.expectAccentValue('Pink');
    app.expectAccent(AppAccent.pink);

    await tour.next();
    await tour.expectStep(TourStep.board);
    await tour.chooseBoardColors(BoardColors.green);
    await tour.chooseBoardPieces(PieceStyle.merida);
    await tour.expectBoardPreview(
      colors: BoardColors.green,
      pieces: PieceStyle.merida,
    );

    await tour.nextUntilLevel();
    await tour.start();
    await home.expectVisible();
    home.expectDark(dark: true);
    app.expectAccent(AppAccent.pink);

    await app.restart();
    await home.expectVisible();
    home.expectDark(dark: true);
    app.expectAccent(AppAccent.pink);
    await home.openSettings();
    await settings.openAppearance();
    settings.expectThemeValue('Dark');
    await settings.expectBoardAppearanceValue('Green · Merida');
  });

  patrolTest('fechar à força no passo do tema: reabre nele, com a cor '
      'escolhida', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);
    await TourRobot($).passVoice();
    await tour.next();
    await tour.chooseThemeMode(AppThemeMode.light);
    await tour.chooseAccent(AppAccent.purple);

    await app.restart();
    await tour.expectStep(TourStep.theme);
    tour.expectAccentValue('Purple');
    app.expectBrightness(Brightness.light);
    app.expectAccent(AppAccent.purple);
  });

  patrolTest('sem escolher cor no tour, o app fica nas cores de fábrica: azul '
      'no claro e verde no escuro', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);
    await TourRobot($).passVoice();
    await tour.next();
    await tour.expectStep(TourStep.theme);

    await tour.chooseThemeMode(AppThemeMode.light);
    tour.expectAccentValue('Blue');
    app.expectAccent(AppAccent.blue);

    await tour.chooseThemeMode(AppThemeMode.dark);
    tour.expectAccentValue('Green');
    app.expectAccent(AppAccent.green);
  });
}
