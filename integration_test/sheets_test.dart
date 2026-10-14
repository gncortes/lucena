import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/core/keys/blind_keys.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/game_sound_keys.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/journey_robot.dart';
import 'robots/sheet_robot.dart';

const _english = Locale('en', 'US');
const _rookShuffle = 'k7/8/8/8/8/8/8/4K2R w - - 0 1';
const _special = '1000/blind.basic.twoRooks.0001';

/// As folhas de baixo (com ✕ por fora) que eram diálogos: abrem com corpo e
/// ✕, o ✕ fecha sem efeito colateral e o jogo segue.
void main() {
  Future<void> openTraining(PatrolIntegrationTester $) async {
    await AppRobot($).open(systemLocale: _english);
    await FreeBoardRobot($).openAt(
      _rookShuffle,
      opponent: 'maia',
      level: 1600,
      user: Side.white,
      goal: 'win',
      white: '300+0',
      black: '300+0',
    );
  }

  Future<void> openBlind(PatrolIntegrationTester $) async {
    final app = AppRobot($);
    final journey = JourneyRobot($);
    await app.open(systemLocale: _english);
    e2eTts.finishes = true;
    await seedAttempt(
      Attempt(
        positionId: 'basic.twoRooks.0001',
        playedAt: DateTime.utc(2026, 10, 7),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        challengeId: '1000/basic.twoRooks.0001',
      ),
    );
    await app.restart();
    await journey.open();
    await journey.openRung('1000');
    await $(JourneyKeys.special(_special)).scrollTo().tap();
    await $(BlindKeys.start).waitUntilVisible();
    await $(BlindKeys.start).tap();
    await $.pumpAndSettle();
    await $(BlindKeys.typeField).waitUntilVisible();
  }

  patrolTest('desistir na partida: a confirmação é uma folha com ✕; o ✕ fecha '
      'sem desistir e o jogo segue', ($) async {
    await openTraining($);
    final board = FreeBoardRobot($);
    final sheet = SheetRobot(
      $,
      surface: FreeBoardKeys.resignSheet,
      close: FreeBoardKeys.confirmationClose,
    );

    await $(FreeBoardKeys.resignButton).tap();
    await sheet.expectOpen();
    await $(FreeBoardKeys.resignConfirmButton).waitUntilVisible();

    await sheet.closeWithX();
    // Nada foi confirmado: sem conclusão, a partida em andamento e o lance
    // seguinte vale.
    expect(find.byKey(ConclusionKeys.screen), findsNothing);
    expect(find.byKey(FreeBoardKeys.resignButton), findsOneWidget);
    await board.move('e1', 'e2');
    expect(find.byKey(ConclusionKeys.screen), findsNothing);

    // Confirmar ainda desiste.
    await board.resign();
    await ConclusionRobot($)
        .expectEnd(title: 'You lost', reason: 'Resignation');
  });

  patrolTest('som da partida: a folha tem corpo e ✕; o ✕ fecha e o jogo '
      'segue', ($) async {
    await openTraining($);
    final board = FreeBoardRobot($);
    final sheet = SheetRobot(
      $,
      surface: GameSoundKeys.dialog,
      close: GameSoundKeys.close,
    );

    await $(FreeBoardKeys.soundButton).tap();
    await $.pumpAndSettle();
    await sheet.expectOpen();
    final enabled = $.tester
        .widget<Switch>(find.byKey(GameSoundKeys.sound))
        .value;

    await sheet.closeWithX();
    // Fechar não mexe no som, e a partida continua.
    await $(FreeBoardKeys.soundButton).tap();
    await $.pumpAndSettle();
    expect(
      $.tester.widget<Switch>(find.byKey(GameSoundKeys.sound)).value,
      enabled,
    );
    await sheet.closeWithX();
    await board.move('e1', 'e2');
    expect(find.byKey(ConclusionKeys.screen), findsNothing);
  });

  patrolTest('às cegas: desistir e a ajuda são folhas com ✕; o ✕ fecha sem '
      'desistir e a partida segue', ($) async {
    await openBlind($);
    final resign = SheetRobot($);

    await $(BlindKeys.resign).tap();
    await $.pumpAndSettle();
    await resign.expectOpen();
    await $(BlindKeys.resignConfirm).waitUntilVisible();
    await resign.closeWithX();
    expect(find.byKey(BlindKeys.result), findsNothing);
    expect(find.byKey(ConclusionKeys.screen), findsNothing);
    expect(find.byKey(BlindKeys.screen), findsOneWidget);
    expect(find.byKey(BlindKeys.typeField), findsOneWidget);

    await $(BlindKeys.help).tap();
    await $.pumpAndSettle();
    await resign.expectOpen();
    await $(BlindKeys.helpSheet).waitUntilExists();
    await resign.closeWithX();
    expect(find.byKey(BlindKeys.helpSheet), findsNothing);
    expect(find.byKey(BlindKeys.typeField), findsOneWidget);
  });
}
