import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/journey_robot.dart';
import 'robots/settings_robot.dart';
import 'robots/tour_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('primeira abertura: tour, escolher 1400 e a Jornada começa no '
      '1400', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);

    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start();

    await HomeRobot($).expectVisible();
    // "Aprender finais" (o marcado na pergunta) é o cartão do alto.
    await $(HomeKeys.goalCard).waitUntilVisible();
    expect(find.byKey(HomeKeys.whereCard), findsNothing);
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
    await tour.openVoice();
    await tour.enterName('Gabriel');

    // Fechar à força no meio do tour não perde o nome.
    await tour.next();
    await app.restart();
    await tour.expectStep(TourStep.school);
    await tour.back();
    await tour.expectStep(TourStep.voice);
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
    await tour.expectStep(TourStep.board);
    await tour.next();
    await tour.expectStep(TourStep.voice);
    await tour.skip();
    await HomeRobot($).expectVisible();
  });

  patrolTest('fechar à força no meio do tour: reabre no mesmo passo', (
    $,
  ) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);
    await tour.nextUntil(TourStep.help);

    await app.restart();
    await tour.expectStep(TourStep.help);
  });

  patrolTest('primeira abertura: tabuleiro verde e peças Mérida no tour valem '
      'no app e continuam ao reabrir', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    final home = HomeRobot($);
    final settings = SettingsRobot($);
    await app.open(systemLocale: _english, tour: true);
    await tour.expectStep(TourStep.board);
    await tour.chooseBoardColors(BoardColors.green);
    await tour.chooseBoardPieces(PieceStyle.merida);
    await tour.expectBoardPreview(
      colors: BoardColors.green,
      pieces: PieceStyle.merida,
    );

    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start();
    await home.expectVisible();

    await app.restart();
    await home.expectVisible();
    await home.openSettings();
    await settings.openAppearance();
    await settings.expectBoardAppearanceValue('Green · Merida');
  });

  patrolTest('depois do tour vem o objetivo; "Já tenho conta" abre a conta, '
      'que volta ao objetivo, e Continuar segue para "Seu nível"', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.finishSteps();
    await $(GoalKeys.screen).waitUntilVisible();
    // Fechado o app aqui, ele volta na pergunta (nada foi dado por visto).
    final saved = await tour.savedOnboarding();
    expect(saved.done, isFalse);
    expect(saved.stage, OnboardingStage.goal);
    await $(GoalKeys.haveAccount).tap();
    await $(AccountKeys.screen).waitUntilVisible();
    await $(AccountKeys.google).tap();
    expect(find.text('Signing in is coming soon.'), findsOneWidget);
    await $(AccountKeys.later).tap();
    await $(GoalKeys.screen).waitUntilVisible();
    await tour.answerGoal();
    await $(LevelKeys.screen).waitUntilVisible();
  });
}
