import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/survey_robot.dart';

const _english = Locale('en', 'US');

void main() {
  patrolTest('finais: o rascunho volta, o envio é offline e o convite some', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final survey = SurveyRobot($);

    await endgames.openFromHome();
    await survey.openInviteFromTrail(SurveyKind.endgames);

    // Passo 1: nota 4 e dois chips, depois Continuar.
    await survey.pickFace(4);
    await survey.pickImprove('examples');
    await survey.pickImprove('exercises');
    await survey.next();
    survey.expectStepTwo();
    await survey.pickInterest(SurveyInterest.maybe);

    // O rascunho sobrevive a fechar à força: volta no passo 2, "Talvez".
    await app.restart();
    await endgames.openFromHome();
    await survey.openInviteFromTrail(SurveyKind.endgames);
    survey.expectStepTwo();
    survey.expectInterest(SurveyInterest.maybe);

    // Sem Wi-Fi nem dados, o envio funciona: a resposta fica no aparelho.
    await app.goOffline();
    try {
      await survey.send();
      await survey.expectThanks();
    } finally {
      await app.goOnline();
    }
    await survey.backFromThanks();
    survey.expectInvite(SurveyKind.endgames, visible: false);

    // Enviada, a resposta continua enviada depois de fechar o app.
    await app.restart();
    await endgames.openFromHome();
    survey.expectInvite(SurveyKind.endgames, visible: false);
  });

  // A Escola está escondida (VisibleLessons.school): o cenário volta quando
  // ela for liberada.
  patrolTest('Escola: o questionário tem 3 passos', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    // Aula da Escola concluída → tela de aula concluída → convite.
    // O caminho completo entra aqui quando a Escola for liberada.
  }, skip: !VisibleLessons.school);
}
