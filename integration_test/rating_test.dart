import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/conclusion_robot.dart';
import 'robots/free_board_robot.dart';
import 'robots/home_robot.dart';
import 'robots/progress_robot.dart';
import 'robots/speedrun_robot.dart';

// Mate em um: Dh8#.
const _mateInOne = '3k4/8/3K4/8/8/8/8/7Q w - - 0 1';

// Rei e torre contra rei, o rei preto longe: a torre vai e volta em h1 e h2
// sem que o rei preto alcance.
const _rookShuffle = 'k7/8/8/8/8/8/8/4K2R w - - 0 1';

const _english = Locale('en', 'US');

void main() {
  /// Joga o mate em um (ou desiste) contra o Maia [level] e sai para a tela
  /// inicial.
  Future<void> play(
    PatrolIntegrationTester $, {
    required bool won,
    int level = 1600,
  }) async {
    final board = FreeBoardRobot($);
    await board.openAt(
      _mateInOne,
      opponent: 'maia',
      level: level,
      user: Side.white,
      goal: 'win',
      position: 'basic.queen.0001',
    );
    if (won) {
      await board.move('h1', 'h8');
    } else {
      await board.resign();
    }
    await ProgressRobot($).expectRatingChanged();
    await ConclusionRobot($).close();
    await HomeRobot($).expectVisible();
  }

  /// Joga a torre de h1 para h2 e de volta [moves] vezes, esperando o Maia de
  /// verdade responder; devolve quanto ele pensou em cada lance.
  Future<List<Duration>> shuffle(PatrolIntegrationTester $, String time) async {
    final board = FreeBoardRobot($);
    e2eOpponent.maiaThinkTimes.clear();
    await board.openAt(
      _rookShuffle,
      opponent: 'maia',
      level: 1400,
      user: Side.white,
      goal: 'win',
      white: time,
      black: time,
    );
    for (var move = 0; move < 4; move++) {
      final (from, to) = move.isEven ? ('h1', 'h2') : ('h2', 'h1');
      await board.move(from, to);
      await board.waitForMoves(move * 2 + 2);
    }
    board.expectStillPlaying();
    await board.leave();
    return [...e2eOpponent.maiaThinkTimes];
  }

  patrolTest('mesma posição em 1+0 e 10+0 contra o Maia 1400: lances legais '
      'nos dois e resposta mais rápida no bullet', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    app.useRealMaia();

    final bullet = await shuffle($, '60+0');
    final rapid = await shuffle($, '600+0');

    Duration sum(List<Duration> times) =>
        times.fold(Duration.zero, (total, time) => total + time);
    expect(bullet, hasLength(4));
    expect(rapid, hasLength(4));
    expect(sum(bullet), lessThan(sum(rapid)));
  });

  patrolTest('no bullet a máquina nunca perde por tempo', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: _english);
    app.useRealMaia();
    await board.openAt(
      _rookShuffle,
      opponent: 'maia',
      level: 1400,
      user: Side.white,
      goal: 'win',
      white: '60+0',
      black: '60+0',
    );

    for (var move = 0; move < 6; move++) {
      final (from, to) = move.isEven ? ('h1', 'h2') : ('h2', 'h1');
      await board.move(from, to);
      await board.waitForMoves(move * 2 + 2);
      board.expectStillPlaying();
    }
    // O relógio do Maia ainda tem quase todo o minuto.
    final machine = e2eOpponent.maiaThinkTimes.fold(
      Duration.zero,
      (total, time) => total + time,
    );
    expect(machine, lessThan(const Duration(seconds: 30)));
  });

  patrolTest('vencer o Maia 1600 sobe o rating, que fica ao reabrir; perder '
      'desce', ($) async {
    final app = AppRobot($);
    final progress = ProgressRobot($);
    await app.open(systemLocale: _english);
    final start = await progress.rating();

    await play($, won: true);
    final afterWin = await progress.rating();
    expect(afterWin, greaterThan(start));

    await app.restart();
    expect(await progress.rating(), afterWin);

    await play($, won: false);
    expect(await progress.rating(), lessThan(afterWin));
  });

  patrolTest('detalhes do rating: sem partidas, o convite; depois, o gráfico '
      'e o histórico com a variação de cada partida', ($) async {
    final app = AppRobot($);
    final progress = ProgressRobot($);
    await app.open(systemLocale: _english);

    await progress.openRatingDetails();
    await progress.expectRatingHistoryEmpty();
    await progress.closeRatingDetails();

    await play($, won: true);
    await play($, won: false);
    await HomeRobot($).expectVisible();

    await progress.openRatingDetails();
    await progress.expectRatingHistory(2, latestChange: '−');
    app.expectNoClippedText();
    await progress.closeRatingDetails();
    await HomeRobot($).expectVisible();
  });

  patrolTest('a etapa de speedrun conta para o rating como a partida comum', (
    $,
  ) async {
    final app = AppRobot($);
    final speedrun = SpeedrunRobot($);
    final board = FreeBoardRobot($);
    final progress = ProgressRobot($);
    await app.open(systemLocale: _english);
    await play($, won: true, level: 1000);
    await progress.expectRatedGames('1 rated game');

    await speedrun.open();
    await speedrun.openSpeedrun('e2e.rung');
    await speedrun.start();
    final (from, to) = E2EJourneyRepository.mate;
    await board.move(from, to);
    await progress.expectRatingChanged();
    // Conclusão da etapa, speedrun e lista: de volta à tela inicial.
    await ConclusionRobot($).close();
    for (var screen = 0; screen < 2; screen++) {
      await speedrun.back();
    }
    await HomeRobot($).expectVisible();

    await progress.expectRatedGames('2 rated games');
  });
}
