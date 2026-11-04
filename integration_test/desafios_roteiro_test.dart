import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/ui/core/keys/featured_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/home_robot.dart';

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
}
