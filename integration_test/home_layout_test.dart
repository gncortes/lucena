import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/home_layout_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/tour_robot.dart';

const _english = Locale('en', 'US');

void main() {
  Future<void> tourAs(PatrolIntegrationTester $, RatingLevel level) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.passVoice();
    await tour.nextUntilLevel();
    await tour.chooseLevel(level);
    await tour.start();
  }

  patrolTest('tour como mestre: o Speedrun primeiro e as aulas fora do '
      'destaque', ($) async {
    await tourAs($, RatingLevel.master);
    await $(HomeKeys.pathsTitle).waitUntilExists();
    final speedrun = $.tester.getTopLeft(find.byKey(HomeKeys.speedrunButton));
    final endgames = $.tester.getTopLeft(find.byKey(HomeKeys.endgamesButton));
    expect(speedrun.dy, lessThan(endgames.dy));
    expect(find.byKey(HomeKeys.schoolButton), findsNothing);
    await $(HomeKeys.otherModes).scrollTo().tap();
    await $(HomeKeys.schoolButton).scrollTo();
  });

  patrolTest('tour como iniciante: Aprender e Jornada em destaque', ($) async {
    await tourAs($, RatingLevel.beginner);
    // O iniciante termina o tour nas aulas; a tela inicial fica embaixo.
    await AppRobot($).restart();
    await $(HomeKeys.schoolButton).waitUntilExists();
    await $(HomeKeys.journeyButton).waitUntilExists();
    expect(find.byKey(HomeKeys.speedrunButton), findsNothing);
  });

  patrolTest('personalizar, fechar o app e reabrir mantém a escolha', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    expect(find.byKey(HomeKeys.speedrunButton), findsNothing);
    await $(HomeKeys.customizeButton).scrollTo().tap();
    await $(HomeLayoutKeys.check(HomePath.speedrun)).scrollTo().tap();
    await app.restart();
    await $(HomeKeys.speedrunButton).scrollTo();
  });
}
