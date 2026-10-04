import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_snapshot.dart';

void main() {
  const startFen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  const clock = ClockState(
    config: ClockConfig(
      white: TimeControl(initial: Duration(minutes: 5)),
      black: TimeControl(initial: Duration(minutes: 5)),
    ),
    white: Duration(minutes: 5),
    black: Duration(minutes: 5),
    running: Side.white,
  );

  test('partida com lances que estava na tela reabre junto com o app', () {
    const snapshot = GameSnapshot(startFen: startFen, moves: ['e2e4']);

    expect(snapshot.reopensOnLaunch, isTrue);
  });

  test('partida sem lances mas com relógio também reabre', () {
    const snapshot = GameSnapshot(startFen: startFen, clock: clock);

    expect(snapshot.reopensOnLaunch, isTrue);
  });

  test('tabuleiro intocado e sem relógio não prende o app na partida', () {
    expect(const GameSnapshot(startFen: startFen).reopensOnLaunch, isFalse);
  });

  test('partida de que o jogador saiu não reabre sozinha', () {
    const snapshot = GameSnapshot(
      startFen: startFen,
      moves: ['e2e4'],
      clock: clock,
      onScreen: false,
    );

    expect(snapshot.reopensOnLaunch, isFalse);
  });
}
