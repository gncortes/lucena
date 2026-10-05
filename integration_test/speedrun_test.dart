import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/speedrun_robot.dart';

// Speedruns curtos da composição dos cenários: todas as etapas são mate em um.
const _rungRun = 'e2e.rung';
const _endingRun = 'e2e.ending';

const _english = Locale('en', 'US');

void main() {
  /// Joga a etapa da vez: o relógio do jogador anda [seconds] e ele dá o mate
  /// (ou desiste, sem [won]). Volta para a tentativa.
  Future<void> playStage(
    PatrolIntegrationTester $,
    int seconds, {
    bool won = true,
  }) async {
    final speedrun = SpeedrunRobot($);
    final board = FreeBoardRobot($);
    await speedrun.playStage();
    await AppRobot($).advanceTime(Duration(seconds: seconds));
    if (won) {
      final (from, to) = E2EJourneyRepository.mate;
      await board.move(from, to);
    } else {
      await board.resign();
    }
    await speedrun.continueAfterGame();
  }

  /// Uma tentativa inteira do speedrun de degrau (duas etapas).
  Future<void> runRung(PatrolIntegrationTester $, int first, int second) async {
    final speedrun = SpeedrunRobot($);
    await speedrun.start();
    await playStage($, first);
    await playStage($, second);
  }

  patrolTest('speedrun de degrau completo: parciais, total e recorde', (
    $,
  ) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_rungRun);

    await speedrun.start();
    await playStage($, 5);
    speedrun.expectStageTime(0, '0:05.0');
    speedrun.expectTotal('0:05.0');
    // Tempo na tela da tentativa (entre etapas) não conta.
    await app.advanceTime(const Duration(minutes: 3));
    await playStage($, 7);

    speedrun.expectStageTime(1, '0:07.0');
    speedrun.expectTotal('0:12.0');
    await speedrun.expectNewRecord(record: true);
    await speedrun.back();
    await speedrun.expectBest('0:12.0');
  });

  patrolTest('mais rápido vira novo recorde; mais lento mantém o recorde', (
    $,
  ) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_rungRun);
    await runRung($, 6, 6);
    await speedrun.back();

    await runRung($, 4, 6);
    await speedrun.expectNewRecord(record: true);
    speedrun.expectRecordDifference('-2.0 s vs. record 0:12.0');
    await speedrun.back();

    await runRung($, 8, 7);
    await speedrun.expectNewRecord(record: false);
    speedrun.expectRecordDifference('+5.0 s vs. record 0:10.0');
    await speedrun.back();
    await speedrun.expectBest('0:10.0');
  });

  patrolTest('perder uma etapa: ela se repete e o tempo perdido conta', (
    $,
  ) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_rungRun);
    await speedrun.start();

    await playStage($, 4, won: false);
    speedrun.expectStageLosses(0, '1 loss');
    speedrun.expectStageTime(0, '0:04.0');
    speedrun.expectPlayButton('Play stage 1 again');

    await playStage($, 3);
    await playStage($, 5);
    speedrun.expectStageTime(0, '0:07.0');
    speedrun.expectTotal('0:12.0');
    await speedrun.expectNewRecord(record: true);
  });

  patrolTest('fechar à força no meio da etapa: tentativa e relógio voltam', (
    $,
  ) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_rungRun);
    await speedrun.start();
    await playStage($, 4);
    await speedrun.playStage();
    await app.advanceTime(const Duration(seconds: 3));

    await app.restart();
    // O app reabre na partida da etapa, com o relógio correndo.
    await board.expectVisible();
    await app.advanceTime(const Duration(seconds: 2));
    final (from, to) = E2EJourneyRepository.mate;
    await board.move(from, to);
    await speedrun.continueAfterGame();

    speedrun.expectStageTime(0, '0:04.0');
    speedrun.expectStageTime(1, '0:05.0');
    speedrun.expectTotal('0:09.0');
    await speedrun.expectNewRecord(record: true);
  });

  patrolTest('speedrun de final: recorde por adversário na tela do final', (
    $,
  ) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_endingRun);

    await speedrun.start();
    await playStage($, 3);
    await playStage($, 4);
    await playStage($, 6);
    await speedrun.expectNewRecord(record: true);
    await speedrun.back();

    await speedrun.expectBest('0:13.0');
    await speedrun.expectStageRecord(0, '0:03.0');
    await speedrun.expectStageRecord(1, '0:04.0');
    await speedrun.expectStageRecord(2, '0:06.0');
    await speedrun.back();
    await speedrun.expectItemBest(_endingRun, '0:13.0');
  });

  patrolTest('desistir no meio: o histórico diz até onde a tentativa foi, e '
      'continua ao reabrir', ($) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_endingRun);

    await speedrun.start();
    await playStage($, 3);
    await speedrun.abandon();
    await speedrun.back();

    await speedrun.expectHistory(0, 'Gave up at stage 2 of 3');
    // Sem tentativa em andamento, dá para começar de novo.
    await speedrun.expectCanStart();

    await app.restart();
    await speedrun.open();
    await speedrun.openSpeedrun(_endingRun);
    await speedrun.expectHistory(0, 'Gave up at stage 2 of 3');
  });

  patrolTest('o ritmo da lista: cada ritmo tem os seus speedruns e a escolha '
      'fica ao reabrir', ($) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);

    await speedrun.open();
    await speedrun.expectItem(_rungRun);
    await speedrun.choosePace('180+2');
    await speedrun.expectItem('$_rungRun@180+2');

    await app.restart();
    await speedrun.open();
    await speedrun.expectItem('$_rungRun@180+2');
  });
}
