import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/home_layout_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/tour_robot.dart';

const _english = Locale('en', 'US');

void main() {
  Future<void> tourAs(PatrolIntegrationTester $, RatingLevel level) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    // Treinar finais: o objetivo sai da lista; as Aulas de finais ficam nela.
    await tour.nextUntilLevel(GoalPreference.train);
    await tour.chooseLevel(level);
    await tour.start();
  }

  // Escola escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('tour como mestre: o Speedrun primeiro e as aulas fora do '
      'destaque', ($) async {
    await tourAs($, RatingLevel.master);
    await $(HomeKeys.shortcutsTitle).waitUntilExists();
    final speedrun = $.tester.getTopLeft(find.byKey(HomeKeys.speedrunButton));
    final endgames = $.tester.getTopLeft(find.byKey(HomeKeys.endgamesButton));
    expect(speedrun.dy, lessThan(endgames.dy));
    expect(find.byKey(HomeKeys.schoolButton), findsNothing);
    await openAllModes($);
    await $(AllModesKeys.item(HomePath.learn.name)).scrollTo();
  }, skip: !VisibleLessons.school);

  // Escola escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('tour como iniciante: Aprender e Jornada em destaque', ($) async {
    await tourAs($, RatingLevel.beginner);
    // O iniciante termina o tour nas aulas; a tela inicial fica embaixo.
    await AppRobot($).restart();
    await $(HomeKeys.schoolButton).waitUntilExists();
    await $(HomeKeys.journeyButton).waitUntilExists();
    expect(find.byKey(HomeKeys.speedrunButton), findsNothing);
  }, skip: !VisibleLessons.school);

  // A tela inicial não tem mais "Personalizar" (T83): a escolha fica em
  // Configurações.
  patrolTest('personalizar, fechar o app e reabrir mantém a escolha', (
    $,
  ) async {
    final app = AppRobot($);
    Future<CheckboxListTile> speedrun() async {
      await HomeRobot($).openSettings();
      await $(SettingsKeys.homeLayoutTile).scrollTo().tap();
      await $(HomeLayoutKeys.check(HomePath.speedrun)).scrollTo();
      return $.tester.widget<CheckboxListTile>(
        find.byKey(HomeLayoutKeys.check(HomePath.speedrun)),
      );
    }

    await app.open(systemLocale: _english);
    final before = (await speedrun()).value;
    await $(HomeLayoutKeys.check(HomePath.speedrun)).tap();
    await app.restart();
    expect((await speedrun()).value, isNot(before));
  });
}
