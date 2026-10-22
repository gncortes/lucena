import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/survey_keys.dart';
import 'package:patrol/patrol.dart';

/// O convite e o questionário "Sua opinião" (E1.05).
class SurveyRobot {
  const SurveyRobot(this.$);

  final PatrolIntegrationTester $;

  /// Rola a trilha de finais até o convite de [kind] e toca em "Responder".
  Future<void> openInviteFromTrail(SurveyKind kind) async {
    await $(SurveyKeys.invite(kind)).scrollTo(maxScrolls: 80);
    await $(SurveyKeys.inviteAction(kind)).tap();
    await $(SurveyKeys.screen).waitUntilVisible();
  }

  void expectInvite(SurveyKind kind, {required bool visible}) {
    expect($(SurveyKeys.invite(kind)).exists, visible);
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

  /// Está no passo 2: as opções de interesse aparecem.
  void expectStepTwo() {
    expect($(SurveyKeys.interest(SurveyInterest.maybe)).exists, isTrue);
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

  Future<void> backFromThanks() async {
    await $(SurveyKeys.thanksBack).tap();
    await $(EndgamesKeys.screen).waitUntilVisible();
  }
}
