import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/home_robot.dart';
import 'robots/placement_robot.dart';
import 'robots/profile_robot.dart';
import 'robots/tour_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('tour: o teste de nível, fechar à força no meio, continuar e '
      'usar o resultado; o tour segue para os caminhos', ($) async {
    final app = AppRobot($);
    final tour = TourRobot($);
    final placement = PlacementRobot($);
    await app.open(systemLocale: _english, tour: true);
    await tour.passVoice();
    await tour.nextUntilLevel();
    // O teste vem primeiro; a lista das faixas, atrás do botão discreto.
    expect(find.byKey(TourKeys.takeTestCard), findsOneWidget);

    await tour.takeTest();
    await placement.expectIntro();
    await placement.start();
    await placement.expectQuestion(1);
    await placement.dontKnow(5);
    await placement.expectQuestion(6);

    // Fechar à força no meio: volta ao passo do nível, e o teste continua
    // na mesma pergunta.
    await app.restart();
    await tour.expectStep(TourStep.level);
    await tour.takeTest();
    await placement.expectIntro();
    await placement.resume();
    await placement.expectQuestion(6);

    await placement.dontKnow(15);
    await placement.expectResult();
    await placement.useLevel();

    await tour.expectStep(TourStep.goals);
    await tour.start();
  });

  patrolTest('no teste, "prefiro informar meu rating" volta ao tour com a '
      'lista das faixas e o aviso', ($) async {
    final tour = TourRobot($);
    await AppRobot($).open(systemLocale: _english, tour: true);
    await tour.passVoice();
    await tour.nextUntilLevel();
    await $(TourKeys.chooseByHand).scrollTo().tap();
    await $.pumpAndSettle();
    await $(TourKeys.byHandHint).waitUntilVisible();
    await $(TourKeys.takeTest).scrollTo();
  });

  patrolTest('perfil: refazer o teste; a escola e a trilha de finais passam '
      'a mostrar o roteiro', ($) async {
    final app = AppRobot($);
    final placement = PlacementRobot($);
    await app.open(systemLocale: _english);
    // Antes do teste: o convite na escola e na trilha.
    final endgames = EndgamesRobot($);
    await endgames.openFromHome();
    await $(EndgamesKeys.placementTest).scrollTo();
    expect(find.byKey(EndgamesKeys.filter), findsNothing);
    // O voltar pelo widget (a dica "Back" muda com o idioma).
    await $(BackButton).tap();
    await $.pumpAndSettle();

    await HomeRobot($).openSettings();
    await ProfileRobot($).open();
    await $(ProfileKeys.placementTest).scrollTo().tap();
    await placement.expectIntro();
    await placement.start();
    await placement.dontKnow(20);
    await placement.expectResult();
    await placement.useLevel();
    await $(ProfileKeys.screen).waitUntilVisible();

    // A trilha agora tem o filtro, e a escolha fica gravada.
    await app.restart();
    await endgames.openFromHome();
    await $(EndgamesKeys.filter).scrollTo();
    expect(find.byKey(EndgamesKeys.placementTest), findsNothing);
    await $(EndgamesKeys.all).tap();
    await $.pumpAndSettle();
    await app.restart();
    await endgames.openFromHome();
    await $(EndgamesKeys.nextEndgame).scrollTo();
    expect(find.byKey(SchoolKeys.placementTest), findsNothing);
  });
}
