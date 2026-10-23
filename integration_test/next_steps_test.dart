import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/tour_robot.dart';

const _english = Locale('en', 'US');

/// E1.34: o fim do tour mostra por onde começar, e a Corrida diz para que
/// serve.
void main() {
  patrolTest('fim do tour: o nível, as opções, o "Em breve" e a Corrida', (
    $,
  ) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start(leave: false);

    await $(NextStepsKeys.screen).waitUntilVisible();
    expect(find.textContaining('Your level: '), findsOneWidget);
    expect(find.byKey(NextStepsKeys.option('lessons')), findsOneWidget);
    await $(NextStepsKeys.comingSoon).scrollTo();
    await $(NextStepsKeys.dataNote).scrollTo();

    // Fechar à força: a primeira abertura já acabou, volta na tela inicial.
    await AppRobot($).restart();
    await HomeRobot($).expectVisible();
  });

  patrolTest('fim do tour: a Corrida abre com a linha do diagnóstico', (
    $,
  ) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start(leave: false);
    await $(NextStepsKeys.option('race')).scrollTo().tap();
    await $(RaceKeys.introView).waitUntilVisible();
    expect(find.byKey(RaceKeys.goalLine), findsOneWidget);
  });
}
