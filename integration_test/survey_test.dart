import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/survey_robot.dart';

const _english = Locale('en', 'US');
const _portuguese = Locale('pt', 'BR');

void main() {
  patrolTest('Pilares: o rascunho volta e o envio é offline', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _portuguese);
    final survey = SurveyRobot($);

    await survey.open(SurveyKind.pilares);

    // Passo 1: nota 4 e dois chips, depois Continuar.
    await survey.pickFace(4);
    await survey.pickImprove('examples');
    await survey.pickImprove('exercises');
    await survey.next();
    survey.expectStepTwo();
    await survey.writeWish('mais finais de torre');

    // O rascunho sobrevive a fechar à força: volta no passo 2 com o texto.
    await app.restart();
    await survey.open(SurveyKind.pilares);
    survey.expectStepTwo(wish: 'mais finais de torre');

    // Sem Wi-Fi nem dados, o envio funciona: a resposta fica no aparelho.
    await app.goOffline();
    try {
      await survey.send();
      await survey.expectThanks();
    } finally {
      await app.goOnline();
    }
    await survey.backFromThanks();
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
