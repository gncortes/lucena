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
  /// A etapa no tabuleiro: o relógio do jogador anda [seconds] e ele dá o
  /// mate (ou desiste, sem [won]).
  Future<void> playStage(
    PatrolIntegrationTester $,
    int seconds, {
    bool won = true,
  }) async {
    final board = FreeBoardRobot($);
    await AppRobot($).advanceTime(Duration(seconds: seconds));
    if (won) {
      final (from, to) = E2EJourneyRepository.mate;
      await board.move(from, to);
    } else {
      await board.resign();
    }
  }

  /// Uma tentativa inteira do speedrun de degrau (duas etapas), até o resumo.
  Future<void> runRung(PatrolIntegrationTester $, int first, int second) async {
    final speedrun = SpeedrunRobot($);
    await speedrun.start();
    await playStage($, first);
    await speedrun.continueToNextStage();
    await playStage($, second);
    await speedrun.finishAttempt();
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
    // Tempo no fim da etapa, antes de seguir, não conta.
    await app.advanceTime(const Duration(minutes: 3));
    await speedrun.continueToNextStage();
    await playStage($, 7);
    await speedrun.finishAttempt();

    speedrun.expectStageTime(0, '0:05.0');
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

  patrolTest('perder uma etapa encerra a tentativa; "tentar novamente" '
      'recomeça da primeira', ($) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_rungRun);
    await speedrun.start();
    await playStage($, 4);
    await speedrun.continueToNextStage();
    await playStage($, 3, won: false);

    // Tentativa nova, da primeira etapa: o tempo da perdida não conta.
    await speedrun.retry();
    await playStage($, 3);
    await speedrun.continueToNextStage();
    await playStage($, 5);
    await speedrun.finishAttempt();
    speedrun.expectStageTime(0, '0:03.0');
    speedrun.expectTotal('0:08.0');
    await speedrun.expectNewRecord(record: true);

    // A perdida fica no histórico, até onde chegou.
    await speedrun.back();
    await speedrun.expectHistory(1, 'Gave up at stage 2 of 2');
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
    await speedrun.continueToNextStage();
    await app.advanceTime(const Duration(seconds: 3));

    await app.restart();
    // O app reabre na partida da etapa, com o relógio correndo.
    await board.expectVisible();
    await playStage($, 2);
    await speedrun.finishAttempt();

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
    await speedrun.continueToNextStage();
    await playStage($, 4);
    await speedrun.continueToNextStage();
    await playStage($, 6);
    await speedrun.finishAttempt();
    await speedrun.expectNewRecord(record: true);
    await speedrun.back();

    await speedrun.expectBest('0:13.0');
    await speedrun.expectStageRecord(0, '0:03.0');
    await speedrun.expectStageRecord(1, '0:04.0');
    await speedrun.expectStageRecord(2, '0:06.0');
    await speedrun.back();
    await speedrun.expectItemBest(_endingRun, '0:13.0');
  });

  patrolTest('sair no meio pede confirmação; o histórico diz até onde a '
      'tentativa foi, também ao reabrir', ($) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun(_endingRun);

    await speedrun.start();
    await playStage($, 3);
    await speedrun.continueToNextStage();
    await speedrun.quit();

    await speedrun.expectHistory(0, 'Gave up at stage 2 of 3');
    // Sem tentativa em andamento, dá para começar de novo.
    await speedrun.expectCanStart();
    // Tocar na tentativa abre o resumo dela, com a marca de cada etapa.
    await speedrun.openHistory(0);
    await speedrun.expectAbandonedDetails(firstStage: '0:03.0');
    await speedrun.back();

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
