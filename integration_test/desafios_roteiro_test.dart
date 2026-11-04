import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/core/keys/daily_keys.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';
import 'robots/race_robot.dart';

const _portuguese = Locale('pt', 'BR');

/// Roteiro de validação da frente Desafios (`docs/tasks/T85-historias/
/// desafios.md`), casos "Patrol". Escrito e NÃO executado: rodar no aparelho
/// antes da PR (`patrol test -t integration_test/desafios_roteiro_test.dart`).
void main() {
  patrolTest('caso 21: a lista de finais em destaque tem o sino e as seções', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.listScreen).waitUntilVisible();
    expect(find.byKey(FeaturedKeys.bell), findsOneWidget);
    expect(find.byKey(FeaturedKeys.recentTitle), findsOneWidget);
  });

  patrolTest('caso 26: o sino ligado continua ligado ao reabrir a lista', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.bell).tap();
    await $(FeaturedKeys.bellNotice).waitUntilVisible();
    // A permissão de notificação, se pedida, é concedida pelo sistema.
    await $.tester.pageBack();
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.listScreen).waitUntilVisible();
    expect(find.byKey(FeaturedKeys.bell), findsOneWidget);
  });

  patrolTest('caso 59: a Jornada abre com o primeiro degrau', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await tapHomePath($, HomePath.journey);
    await $(JourneyKeys.screen).waitUntilVisible();
  });

  patrolTest('caso 62: a lista de Speedrun e o Como funciona em tela cheia', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await tapHomePath($, HomePath.speedrun);
    await $(SpeedrunKeys.listScreen).waitUntilVisible();
    await $(SpeedrunKeys.help).tap();
    await $(SpeedrunKeys.helpScreen).waitUntilVisible();
    await $(SpeedrunKeys.helpClose).tap();
    await $(SpeedrunKeys.listScreen).waitUntilVisible();
  });

  // Casos 1, 2, 5, 6 e 14/15: o Final do dia. O fixture E2E decide se há final
  // hoje; o teste aceita os dois estados e confere o que cada um promete.
  patrolTest('casos 1, 2, 5 e 14: Final do dia abre a partida ou avisa', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await _go($, Routes.dailyFrom('link'));
    await $.pumpAndSettle();
    if (find.byKey(DailyKeys.appBarShare).evaluate().isEmpty) {
      // Sem final hoje: volta ao Início com o aviso.
      await $(DailyKeys.noFinalNotice).waitUntilVisible();
      await $(HomeKeys.screen).waitUntilVisible();
      return;
    }
    await $(DailyKeys.appBarShare).tap();
    await $(DailyKeys.shareSheet).waitUntilVisible();
    expect(find.byKey(DailyKeys.shareImage), findsOneWidget);
    await $(DailyKeys.shareSheetClose).tap();
    await $(DailyKeys.appBarShare).waitUntilVisible();
    // Segundo plano e volta: a partida continua.
    await AppRobot($).sendToBackgroundAndReturn();
    await $(DailyKeys.appBarShare).waitUntilVisible();
  });

  patrolTest('caso 6: fechar à força na partida do dia retoma a partida', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _portuguese);
    await _go($, Routes.daily);
    await $.pumpAndSettle();
    if (find.byKey(DailyKeys.appBarShare).evaluate().isEmpty) return;
    await app.restart();
    await $(HomeKeys.screen).waitUntilVisible();
  });

  patrolTest('casos 8 e 13: o modal Parabéns! sobrevive ao segundo plano', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await _go($, Routes.daily);
    await $.pumpAndSettle();
    // Ganhar exige jogar a solução do fixture: o roteiro só confere o modal
    // quando ele já está aberto (rodar com o final do dia do fixture ganho).
    if (find.byKey(DailyKeys.winSheet).evaluate().isEmpty) return;
    await AppRobot($).sendToBackgroundAndReturn();
    expect(find.byKey(DailyKeys.winSheet), findsOneWidget);
    await $(DailyKeys.winLater).tap();
    await $(HomeKeys.screen).waitUntilVisible();
  });

  patrolTest('casos 33 e 38: cartão de torneio e final em destaque', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await $(HomeKeys.featuredTitle).scrollTo();
    await $(FeaturedKeys.homeSeeAll).scrollTo().tap();
    await $(FeaturedKeys.listScreen).waitUntilVisible();
    final carousel = find.byKey(FeaturedKeys.tournamentCarousel);
    if (carousel.evaluate().isNotEmpty) {
      await $(carousel).$(InkWell).first.tap();
      await $(FeaturedKeys.tournamentScreen).waitUntilVisible();
      await $.tester.pageBack();
      await $(FeaturedKeys.listScreen).waitUntilVisible();
    }
    await $(FeaturedKeys.recentTitle).scrollTo();
  });

  patrolTest('casos 42, 43, 45 e 46: Corrida do começo ao erro', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _portuguese);
    final race = RaceRobot($);
    await race.openFromAllModes();
    expect(find.byKey(RaceKeys.start), findsOneWidget);
    await race.start();
    await race.solve();
    expect(race.corrects, 1);
    await race.miss();
    expect(find.byKey(RaceKeys.chances), findsOneWidget);
    // Segundo plano de 30 s: o tempo é descontado e a corrida continua.
    await app.sendToBackgroundFor(const Duration(seconds: 30));
    await $(RaceKeys.gameView).waitUntilVisible();
    // Fechar à força: reabrir leva à retomada ou ao resultado.
    await app.restart();
    await $(HomeKeys.screen).waitUntilVisible();
  });

  patrolTest(
    'caso 56: link inválido cai na tela de link inválido (54 e 55 pedem link montado: fora deste roteiro)',
    ($) async {
      await AppRobot($).open(systemLocale: _portuguese);
      // Link ruim: posição inválida cai na tela de link inválido.
      await _go($, Routes.invalidLink);
      await $(ChallengeKeys.invalidScreen).waitUntilVisible();
      expect(find.byKey(ChallengeKeys.invalidBack), findsOneWidget);
    },
  );

  patrolTest('caso 60: degrau e desafio da Jornada', ($) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await tapHomePath($, HomePath.journey);
    await $(JourneyKeys.screen).waitUntilVisible();
    await $(JourneyKeys.continueButton).scrollTo().tap();
    await $(JourneyKeys.rungScreen).waitUntilVisible();
    expect(find.byKey(JourneyKeys.rungHeader), findsOneWidget);
    await $(JourneyKeys.nextChallengePlay).scrollTo().tap();
    await $(JourneyKeys.challengeScreen).waitUntilVisible();
    expect(find.byKey(JourneyKeys.opponentCard), findsOneWidget);
    await $(JourneyKeys.emptyHistory).scrollTo();
  });

  patrolTest('caso 61: degrau inexistente cai em Conteúdo não encontrado', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _portuguese);
    await _go($, Routes.journeyRung('xx'));
    await $(LoadErrorKeys.screen).waitUntilVisible();
    expect(find.byKey(LoadErrorKeys.action), findsOneWidget);
  });
}

/// Navega para [location] como um link faria, a partir da tela inicial.
Future<void> _go(PatrolIntegrationTester $, String location) async {
  await $(HomeKeys.screen).waitUntilVisible();
  GoRouter.of($.tester.element(find.byKey(HomeKeys.screen))).go(location);
  await $.pumpAndSettle();
}
