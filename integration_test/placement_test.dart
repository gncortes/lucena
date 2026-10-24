import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
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
    await tour.nextUntilLevel();
    expect(find.byKey(LevelKeys.option(LevelChoice.test)), findsOneWidget);

    await tour.takeTest();
    // O teste marcado em "Seu nível" abre ao tocar em "Continuar".
    await tour.start(leave: false);
    await placement.expectIntro();
    await placement.start();
    await placement.expectQuestion(1);
    await placement.dontKnow(5);
    await placement.expectQuestion(6);

    // Fechar à força no meio: a primeira abertura volta em "Seu nível" (só
    // ele a fecha), e o teste continua na mesma pergunta.
    await app.restart();
    await $(LevelKeys.screen).waitUntilVisible();
    await tour.takeTest();
    // O teste marcado em "Seu nível" abre ao tocar em "Continuar".
    await tour.start(leave: false);
    await placement.expectIntro();
    await placement.resume();
    await placement.expectQuestion(6);

    await placement.dontKnow(15);
    await placement.expectResult();
    await placement.useLevel();

    await $(LevelKeys.screen).waitUntilVisible();
    await tour.start();
    await tour.leaveNextSteps();
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
    await ProfileRobot($).openPlacement();
    await placement.expectIntro();
    await placement.start();
    await placement.dontKnow(20);
    await placement.expectResult();
    await placement.useLevel();
    // O resultado volta a "Seu nível", de onde o teste foi aberto.
    await $(LevelKeys.screen).waitUntilVisible();

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
