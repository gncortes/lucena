import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/progress_robot.dart';
import 'robots/speedrun_robot.dart';
import 'robots/variant.dart';

// Mate em um: Dh8#.
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

const _english = Locale('en', 'US');

void main() {
  /// Vence o mate em um contra o Maia 1000 e devolve as mensagens do fim.
  Future<List<String>> win(PatrolIntegrationTester $) async {
    final board = FreeBoardRobot($);
    await board.openAt(
      _mateInOne,
      opponent: 'maia',
      level: 1000,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );
    await board.move('h1', 'h8');
    await ProgressRobot($).expectRatingChanged();
    final feedback = await ProgressRobot($).feedback();
    await board.leave();
    await HomeRobot($).expectVisible();
    return feedback;
  }

  /// Joga a etapa da vez em [seconds] segundos do relógio do jogador.
  Future<void> playStage(PatrolIntegrationTester $, int seconds) async {
    final speedrun = SpeedrunRobot($);
    await speedrun.playStage();
    await AppRobot($).advanceTime(Duration(seconds: seconds));
    final (from, to) = E2EJourneyRepository.mate;
    await FreeBoardRobot($).move(from, to);
    await speedrun.continueAfterGame();
  }

  patrolTest('primeiro final concluído: a conquista aparece e continua ao '
      'reabrir', ($) async {
    final app = AppRobot($);
    final progress = ProgressRobot($);
    await app.open(systemLocale: _english);

    final feedback = await win($);
    if (e2eTranslated) {
      // Em árabe: a primeira vitória e a conquista, traduzidas.
      expect(feedback, hasLength(2));
    } else {
      expect(feedback, contains('Achievement unlocked: First endgame'));
      expect(feedback, contains('You beat Coco for the first time!'));
    }

    await app.restart();
    await progress.openAchievements();
    await progress.expectUnlocked('first-fulfilled');
    await progress.expectLocked('beat-stockfish');
  });

  patrolTest('conquista nova: o aviso desce por cima da partida com o nome '
      'dela e some sozinho', ($) async {
    final board = FreeBoardRobot($);
    await AppRobot($).open(systemLocale: _english);
    await board.openAt(
      _mateInOne,
      opponent: 'maia',
      level: 1000,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );

    // Sem relógio, a linha do jogador diz que é a vez dele.
    board.expectTurn('Your turn');
    await board.move('h1', 'h8', settle: false);

    await ProgressRobot($).expectAchievementToast('First endgame');
  });

  patrolTest('conquista já obtida não aparece de novo como nova', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    await win($);

    final second = await win($);
    expect(second.where((text) => text.startsWith('Achievement')), isEmpty);
    expect(second.where((text) => text.startsWith('You beat')), isEmpty);
  });

  patrolTest('speedrun completo pausado: reabrir o app volta ao mesmo ponto '
      'e tempo', ($) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun('e2e.full');
    await speedrun.start();
    await playStage($, 9);
    speedrun.expectTotal('0:09.0');

    // Pausa longa entre as etapas, com o app fechado.
    await app.advanceTime(const Duration(days: 2));
    await app.restart();
    await speedrun.open();
    await speedrun.openSpeedrun('e2e.full');
    await $(SpeedrunKeys.resume).scrollTo().tap();
    await $(SpeedrunKeys.attemptScreen).waitUntilVisible();
    speedrun
      ..expectStageTime(0, '0:09.0')
      ..expectTotal('0:09.0');

    await playStage($, 4);
    await playStage($, 6);
    speedrun.expectTotal('0:19.0');
    await speedrun.expectNewRecord(record: true);
  });

  patrolTest('speedrun de exercícios até o fim: recorde gravado', ($) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun('e2e.exercises');
    await speedrun.start();
    await playStage($, 3);
    await playStage($, 5);

    speedrun.expectTotal('0:08.0');
    await speedrun.expectNewRecord(record: true);
    await speedrun.back();
    await speedrun.expectBest('0:08.0');
    await app.restart();
    await speedrun.open();
    await $(SpeedrunKeys.item('e2e.exercises')).scrollTo();
    await speedrun.expectItemBest('e2e.exercises', '0:08.0');
  });
}
