import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/daily_keys.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/privacy_keys.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:lucena/ui/core/keys/week_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';

/// Telas que a tela inicial alcança e nenhum outro cenário abria: todos os
/// modos, o final do dia, a sequência, a semana e a privacidade.
void main() {
  Future<void> goTo(PatrolIntegrationTester $, String route) async {
    final context = $.tester.element(find.byKey(HomeKeys.screen));
    GoRouter.of(context).go(route);
    await $.pumpAndSettle();
  }

  patrolTest('todos os modos: a lista abre e um modo leva à tela dele', (
    $,
  ) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await $(HomeKeys.allModesButton).tap();
    await $(AllModesKeys.screen).waitUntilVisible();
    await $(AllModesKeys.item('journey')).scrollTo();

    await $(AllModesKeys.item('endgames')).scrollTo().tap();
    await $(EndgamesKeys.screen).waitUntilVisible();
  });

  patrolTest('final do dia: o cartão da tela inicial abre a partida do dia', (
    $,
  ) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await $(DailyKeys.homeStrip).scrollTo();
    await $(DailyKeys.badge).scrollTo().tap();

    await FreeBoardRobot($).expectVisible();
  });

  patrolTest('sequência: a tela abre sem dias seguidos', ($) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await goTo($, Routes.streak);

    await $(StreakKeys.screen).waitUntilVisible();
    await $(StreakKeys.current).waitUntilExists();
    await $(StreakKeys.record).waitUntilExists();
  });

  patrolTest('semana: o resumo abre e "Jogar" leva ao final do dia', ($) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await goTo($, Routes.week);

    await $(WeekKeys.screen).waitUntilVisible();
    await $(WeekKeys.headline).waitUntilVisible();
    await $(WeekKeys.play).scrollTo().tap();
    await FreeBoardRobot($).expectVisible();
  });

  patrolTest('privacidade: a tela abre com o cartão do app gratuito', (
    $,
  ) async {
    await AppRobot($).open();
    await HomeRobot($).expectVisible();

    await goTo($, Routes.privacy);

    await $(PrivacyKeys.screen).waitUntilVisible();
    await $(PrivacyKeys.policy).scrollTo();
  });
}
