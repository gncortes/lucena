import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/free_board_robot.dart';

const _queenMate = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

/// O tempo de pensar do Maia de verdade. Nos cenários o relógio não anda
/// sozinho: ele anda o que o Maia "pensou" em cada lance.
void main() {
  patrolTest('3+2: tempos variados e a máquina não perde por tempo', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    app.useRealMaia();
    await board.openAt(
      _queenMate,
      opponent: 'maia',
      level: 1400,
      user: Side.white,
      white: '180+2',
      black: '180+2',
    );

    await board.move('c1', 'g5');
    await board.waitForMoves(2);
    await board.move('c2', 'b2');
    await board.waitForMoves(4);
    await board.move('b2', 'a2');
    await board.waitForMoves(6);

    final times = app.maiaThinkTimes;
    expect(times, hasLength(3));
    expect(times.toSet().length, greaterThan(1), reason: '$times');
    for (final time in times) {
      expect(time, greaterThan(Duration.zero));
      expect(time, lessThanOrEqualTo(const Duration(seconds: 2)));
    }
    board.expectStillPlaying();
    // Com 2 s de incremento por lance, ela está com mais tempo do que começou.
    await board.expectClock(Side.black, _clockAfter(times));
  });

  patrolTest('recaptura óbvia: a resposta sai quase na hora', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    app.useRealMaia();
    // 1.e4 d5 2.exd5 Cf6 3.Cc3 Cxd5: o jogador toma em d5 e as pretas retomam.
    await board.openAt(
      'rnbqkb1r/ppp1pppp/8/3n4/8/2N5/PPPP1PPP/R1BQKBNR w KQkq - 0 4',
      opponent: 'maia',
      level: 1800,
      user: Side.white,
      white: '180+2',
      black: '180+2',
    );

    await board.move('c3', 'd5');
    final moves = await board.waitForMoves(2);

    expect(moves, ['Nxd5', 'Qxd5']);
    expect(
      app.maiaThinkTimes.single,
      lessThan(const Duration(milliseconds: 400)),
    );
  });

  patrolTest('máquina com menos de 10 s: joga mais rápido', ($) async {
    final app = AppRobot($);
    final board = FreeBoardRobot($);
    await app.open(systemLocale: const Locale('en', 'US'));
    app.useRealMaia();
    await board.openAt(
      _queenMate,
      opponent: 'maia',
      level: 1400,
      user: Side.white,
      white: '180+2',
      black: '8+2',
    );

    await board.move('c1', 'g5');
    await board.waitForMoves(2);

    // Com tempo de sobra ela poderia pensar até 2 s; apurada, no máximo 0,5 s.
    expect(
      app.maiaThinkTimes.single,
      lessThanOrEqualTo(const Duration(milliseconds: 500)),
    );
    board.expectStillPlaying();
  });
}

// O relógio das pretas depois de três lances numa partida 3+2, como aparece
// na tela (minutos e segundos inteiros).
String _clockAfter(List<Duration> thinkTimes) {
  var remaining = const Duration(minutes: 3);
  for (final time in thinkTimes) {
    remaining = remaining - time + const Duration(seconds: 2);
  }
  final seconds = remaining.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
