import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
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
    await tour.expectStep(TourStep.level);
    await tour.takeTest();
    // O teste marcado em "Seu nível" abre ao tocar em "Continuar".
    await tour.start(leave: false);
    await placement.expectIntro();
    await placement.resume();
    await placement.expectQuestion(6);

    await placement.dontKnow(15);
    await placement.expectResult();
    await placement.useLevel();

    // "Usar esse rating" leva ao passo Região; o resto do tour termina.
    await tour.expectStep(TourStep.region);
    await tour.leaveNextSteps();
  });

  // A V1 tem só o Pilares (decisão do Gabriel): a trilha de finais fica
  // oculta e o atalho Pilares abre o curso. O teste refeito pelo perfil se
  // confere no Início e na Escola, não mais na trilha.
  patrolTest('perfil: refazer o teste; o Início e a Escola seguem com o '
      'novo degrau', ($) async {
    final app = AppRobot($);
    final placement = PlacementRobot($);
    await app.open(systemLocale: _english);

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

    // Depois de fechar o app: o Início mostra o rating, segue com o atalho
    // do Pilares e não convida mais para o teste.
    await app.restart();
    await HomeRobot($).expectRating();
    await $(HomeKeys.pillarsButton).scrollTo();
    expect(find.byKey(SchoolKeys.placementTest), findsNothing);
  });
}
