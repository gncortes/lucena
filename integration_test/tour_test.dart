import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/journey_robot.dart';
import 'robots/tour_robot.dart';
import 'robots/variant.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('primeira abertura: tour, escolher 1400 e a Jornada começa no '
      '1400', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.expectStep(TourStep.goal);

    await tour.nextUntilLevel();
    await tour.chooseLevel(RatingLevel.intermediate);
    await tour.start();

    await HomeRobot($).expectVisible();
    await $(HomeKeys.whereTitle).waitUntilVisible();
    expectText(
      $.tester.widget<Text>(find.byKey(HomeKeys.whereTitle)).data,
      'You are at Maia 1400',
    );
    final journey = JourneyRobot($);
    await journey.open();
    await journey.expectCurrent('Percival');
    await journey.expectUnlocked('1000');
    await journey.expectLocked('1600');
  });

  patrolTest('pular o tour: ao reabrir ele não aparece de novo', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);
    await tour.expectStep(TourStep.goal);
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
    await tour.expectStep(TourStep.goal);
    await tour.next();
    await tour.expectStep(TourStep.rating);
    await tour.skip();
    await HomeRobot($).expectVisible();
  });

  patrolTest('fechar à força no meio do tour: reabre no mesmo passo', (
    $,
  ) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    await app.open(systemLocale: _english, tour: true);
    await tour.next();
    await tour.next();
    await tour.next();
    await tour.expectStep(TourStep.endgames);

    await app.restart();
    await tour.expectStep(TourStep.endgames);
  });
}
