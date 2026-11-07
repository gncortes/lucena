import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/survey_keys.dart';
import 'package:patrol/patrol.dart';

/// O convite e o questionário "Sua opinião" (E1.05).
class SurveyRobot {
  const SurveyRobot(this.$);

  final PatrolIntegrationTester $;

  /// Abre a pesquisa de [kind] por cima da tela atual, como o convite do
  /// fim de lição faz (o convite em si tem teste de widget; chegar ao fim de
  /// uma lição real aqui custaria minutos).
  Future<void> open(SurveyKind kind) async {
    final context = $.tester.element(find.byType(Scaffold).first);
    unawaited(GoRouter.of(context).push(Routes.survey(kind, origin: 'e2e')));
    await $(SurveyKeys.screen).waitUntilVisible();
  }

  Future<void> pickFace(int n) async {
    await $(SurveyKeys.face(n)).tap();
  }

  Future<void> pickImprove(String id) async {
    await $(SurveyKeys.improveChip(id)).scrollTo().tap();
  }

  Future<void> next() async {
    await $(SurveyKeys.next).tap();
    await $.pumpAndSettle();
  }

  Future<void> send() async {
    await $(SurveyKeys.send).tap();
    await $.pumpAndSettle();
  }

  Future<void> pickInterest(SurveyInterest interest) async {
    await $(SurveyKeys.interest(interest)).scrollTo().tap();
  }

  Future<void> writeWish(String text) async {
    await $(SurveyKeys.wishText).scrollTo().enterText(text);
  }

  /// Está no passo 2 do Pilares: o campo "O que mais você gostaria de ver?".
  void expectStepTwo({String? wish}) {
    expect($(SurveyKeys.wishText).exists, isTrue);
    if (wish != null) expect($(wish).exists, isTrue);
  }

  /// A opção [interest] está marcada.
  void expectInterest(SurveyInterest interest) {
    final group = $.tester.widget<RadioGroup<SurveyInterest>>(
      find.byType(RadioGroup<SurveyInterest>),
    );
    expect(group.groupValue, interest);
  }

  Future<void> expectThanks() async {
    await $(SurveyKeys.thanks).waitUntilVisible();
  }

  /// "Voltar ao Pilares": a pesquisa saiu da pilha, volta à tela de origem.
  Future<void> backFromThanks() async {
    await $(SurveyKeys.thanksBack).tap();
    await $.pumpAndSettle();
    expect($(SurveyKeys.thanks).exists, isFalse);
    expect($(SurveyKeys.screen).exists, isFalse);
  }
}
