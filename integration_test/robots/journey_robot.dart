import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:patrol/patrol.dart';

import 'variant.dart';

/// Telas da Jornada: degraus, desafios e o histórico de cada desafio.
class JourneyRobot {
  const JourneyRobot(this.$);

  final PatrolIntegrationTester $;

  /// A partir da tela inicial.
  Future<void> open() async {
    await $(HomeKeys.journeyButton).scrollTo().tap();
    await $(JourneyKeys.screen).waitUntilVisible();
    await $(JourneyKeys.current).waitUntilVisible();
  }

  Future<void> openRung(String id) async {
    await $(JourneyKeys.rung(id)).scrollTo().tap();
    await $(JourneyKeys.rungScreen).waitUntilVisible();
  }

  Future<void> openChallenge(String position) async {
    await $(JourneyKeys.challenge(position)).scrollTo().tap();
    await $(JourneyKeys.challengeScreen).waitUntilVisible();
    await $(JourneyKeys.play).waitUntilVisible();
  }

  /// "Jogar" no desafio aberto: a partida abre no tabuleiro.
  Future<void> play() async {
    await $(JourneyKeys.play).tap();
    await $(FreeBoardKeys.board).waitUntilVisible();
  }

  Future<void> back() async {
    await $(BackButton).tap();
    await $.pumpAndSettle();
  }

  void expectCurrent(String text) {
    expectText(_text(JourneyKeys.current), text);
  }

  Future<void> expectLocked(String id) async {
    await $(JourneyKeys.rung(id)).scrollTo();
    expect(find.byKey(JourneyKeys.rungLocked(id)), findsOneWidget);
  }

  Future<void> expectUnlocked(String id) async {
    await $(JourneyKeys.rung(id)).scrollTo();
    expect(find.byKey(JourneyKeys.rungLocked(id)), findsNothing);
  }

  Future<void> expectCompleted(String id) async {
    await $(JourneyKeys.rung(id)).scrollTo();
    expect(find.byKey(JourneyKeys.rungCompleted(id)), findsOneWidget);
  }

  /// Toca no degrau trancado: aparece o que falta no anterior.
  Future<void> tapLockedAndExpectMessage(String id, String text) async {
    await $(JourneyKeys.rung(id)).scrollTo().tap();
    await $(JourneyKeys.lockedMessage).waitUntilVisible();
    expectText(_text(JourneyKeys.lockedMessage), text);
    expect(find.byKey(JourneyKeys.rungScreen), findsNothing);
  }

  Future<void> expectChallengeDone(String position, {bool done = true}) async {
    await $(JourneyKeys.challenge(position)).scrollTo();
    expect(
      find.byKey(JourneyKeys.challengeDone(position)),
      done ? findsOneWidget : findsNothing,
    );
  }

  /// Os títulos de mês do histórico, de cima para baixo.
  void expectMonths(List<String> months) {
    for (final (index, month) in months.indexed) {
      expectText(_text(JourneyKeys.month(index)), month);
    }
    expect(find.byKey(JourneyKeys.month(months.length)), findsNothing);
  }

  /// Quantas partidas o histórico mostra.
  void expectAttempts(int count) {
    expect(find.byKey(JourneyKeys.attempt(count - 1)), findsOneWidget);
    expect(find.byKey(JourneyKeys.attempt(count)), findsNothing);
  }

  String? _text(Key key) => $.tester.widget<Text>(find.byKey(key)).data;
}
