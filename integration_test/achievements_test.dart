import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/journey_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/game_details_robot.dart';
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
    await ConclusionRobot($).close();
    await HomeRobot($).expectVisible();
    return feedback;
  }

  /// A etapa no tabuleiro, vencida em [seconds] segundos do relógio do
  /// jogador.
  Future<void> playStage(PatrolIntegrationTester $, int seconds) async {
    await AppRobot($).advanceTime(Duration(seconds: seconds));
    final (from, to) = E2EJourneyRepository.mate;
    await FreeBoardRobot($).move(from, to);
  }

  patrolTest('primeiro final concluído: a conquista aparece e continua ao '
      'reabrir', ($) async {
    final app = AppRobot($);
    final progress = ProgressRobot($);
    await app.open(systemLocale: _english);

    final feedback = await win($);
    if (e2eTranslated) {
      // Em árabe: a primeira vitória e as duas conquistas (o primeiro final e
      // a vitória contra o personagem), traduzidas.
      expect(feedback, hasLength(3));
    } else {
      // As conquistas vêm em cartões, com o nome delas.
      expect(feedback, contains('First endgame'));
      expect(feedback, contains('Beat Coco'));
      expect(feedback, contains('You beat Coco for the first time!'));
    }

    await app.restart();
    await progress.openAchievements();
    await progress.expectUnlocked('first-fulfilled');
    // A de cada personagem só sai vencendo ele mesmo.
    await progress.expectUnlocked('beat-1000');
    await progress.expectLocked('beat-1200');
    await progress.expectLocked('beat-stockfish');
  });

  patrolTest('conquista nova: o aviso desce por cima da conclusão com o nome '
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

  patrolTest('conquista nova: tocar no aviso abre o detalhe com a data, e '
      '"Ver a partida" abre a revisão desta partida', ($) async {
    final board = FreeBoardRobot($);
    final progress = ProgressRobot($);
    await AppRobot($).open(systemLocale: _english);
    await board.openAt(
      _mateInOne,
      opponent: 'maia',
      level: 1000,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );
    await board.move('h1', 'h8', settle: false);

    await progress.tapAchievementToast();
    await progress.expectDetailUnlocked('First endgame');
    await progress.openDetailGame();
    // A revisão é a desta partida: o mate em um, do lance da dama.
    final details = GameDetailsRobot($).state;
    expect(details.attempt?.positionId, 'basic.queen.0001');
    expect(details.attempt?.moves, ['h1h8']);
  });

  patrolTest('conquista que falta: o detalhe mostra o atalho, que leva ao '
      'degrau do adversário', ($) async {
    final progress = ProgressRobot($);
    await AppRobot($).open(systemLocale: _english);
    await progress.openAchievements();

    await progress.openAchievement('beat-1000');
    await progress.expectDetailLocked('Play against Coco');
    await progress.tapDetailShortcut();
    await $(JourneyKeys.rungScreen).waitUntilVisible();
  });

  patrolTest('conquista já obtida não aparece de novo como nova', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    await win($);

    final second = await win($);
    expect(second.where((text) => text.startsWith('Achievement')), isEmpty);
    expect(second.where((text) => text.startsWith('You beat')), isEmpty);
  });

  patrolTest('speedrun completo com o app fechado no meio de uma etapa: '
      'reabrir volta à etapa e ao tempo', ($) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    await app.open(systemLocale: _english);
    await speedrun.open();
    await speedrun.openSpeedrun('e2e.full');
    await speedrun.start();
    await playStage($, 9);
    await speedrun.continueToNextStage();
    await app.advanceTime(const Duration(seconds: 2));

    // O app fecha no meio da segunda etapa e reabre nela, com o relógio
    // como estava.
    await app.restart();
    await FreeBoardRobot($).expectVisible();
    await playStage($, 2);
    await speedrun.continueToNextStage();
    await playStage($, 6);
    await speedrun.finishAttempt();

    await speedrun.expectStageTime(0, '9.0 s');
    await speedrun.expectStageTime(1, '4.0 s');
    await speedrun.expectTotal('19.0 s');
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
    await speedrun.continueToNextStage();
    await playStage($, 5);
    await speedrun.finishAttempt();

    await speedrun.expectTotal('8.0 s');
    await speedrun.expectNewRecord(record: true);
    await speedrun.back();
    await speedrun.expectBest('0:08.0');
    await app.restart();
    await speedrun.open();
    await $(SpeedrunKeys.item('e2e.exercises')).scrollTo();
    await speedrun.expectItemBest('e2e.exercises', '0:08.0');
  });
}
