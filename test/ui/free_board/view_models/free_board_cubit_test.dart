import 'package:bloc_test/bloc_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

void main() {
  void playAll(FreeBoardCubit cubit, List<String> ucis) {
    for (final uci in ucis) {
      cubit.play(NormalMove.fromUci(uci));
    }
  }

  test('abre na posição inicial, sem lances', () {
    final state = FreeBoardCubit().state;

    expect(state.position, GameRules.initial);
    expect(state.moves, isEmpty);
    expect(state.lastMove, isNull);
    expect(state.end, isNull);
  });

  blocTest<FreeBoardCubit, FreeBoardState>(
    'e4 e5 Cf3: a lista ganha os três lances e a vez passa',
    build: FreeBoardCubit.new,
    act: (cubit) => playAll(cubit, ['e2e4', 'e7e5', 'g1f3']),
    skip: 2,
    verify: (cubit) {
      expect(cubit.state.moves, ['e4', 'e5', 'Nf3']);
      expect(cubit.state.position.turn, Side.black);
      expect(cubit.state.lastMove, NormalMove.fromUci('g1f3'));
    },
  );

  blocTest<FreeBoardCubit, FreeBoardState>(
    'lance ilegal não muda nada',
    build: FreeBoardCubit.new,
    act: (cubit) => playAll(cubit, ['e2e5', 'e7e5']),
    expect: () => <FreeBoardState>[],
  );

  blocTest<FreeBoardCubit, FreeBoardState>(
    'mate do pastor termina a partida e trava o tabuleiro',
    build: FreeBoardCubit.new,
    act: (cubit) => playAll(cubit, [
      'e2e4',
      'e7e5',
      'f1c4',
      'b8c6',
      'd1h5',
      'g8f6',
      'h5f7',
      'e8f7',
    ]),
    verify: (cubit) {
      expect(cubit.state.moves, hasLength(7));
      expect(cubit.state.moves.last, 'Qxf7#');
      expect(
        cubit.state.end,
        const GameEnd(GameEndReason.checkmate, winner: Side.white),
      );
    },
  );

  blocTest<FreeBoardCubit, FreeBoardState>(
    'nova partida volta à posição inicial e limpa a lista',
    build: FreeBoardCubit.new,
    act: (cubit) {
      playAll(cubit, ['e2e4', 'e7e5']);
      cubit.newGame();
    },
    skip: 2,
    expect: () => [
      const FreeBoardState(
        start: GameRules.initial,
        position: GameRules.initial,
      ),
    ],
  );

  test('com posição preparada, abre nela e "nova partida" volta para ela', () {
    final start = GameRules.fromFen('8/P6k/8/8/8/8/8/K7 w - - 0 1')!;
    final cubit = FreeBoardCubit(start: start);
    addTearDown(cubit.close);

    cubit.play(NormalMove.fromUci('a7a8n'));
    expect(cubit.state.moves, ['a8=N']);

    cubit.newGame();
    expect(cubit.state.position, start);
    expect(cubit.state.moves, isEmpty);
  });

  test('sem lado escolhido, o jogador move os dois e vê pelas brancas', () {
    final state = FreeBoardCubit().state;

    expect(state.playerSide, isNull);
    expect(state.orientation, Side.white);
  });

  test('jogando de pretas, o tabuleiro abre virado para as pretas', () {
    final state = FreeBoardCubit(playerSide: Side.black).state;

    expect(state.playerSide, Side.black);
    expect(state.orientation, Side.black);
  });

  blocTest<FreeBoardCubit, FreeBoardState>(
    'virar o tabuleiro inverte a orientação e não mexe na partida',
    build: FreeBoardCubit.new,
    act: (cubit) {
      playAll(cubit, ['e2e4', 'e7e5']);
      cubit.flip();
    },
    skip: 2,
    verify: (cubit) {
      expect(cubit.state.orientation, Side.black);
      expect(cubit.state.moves, ['e4', 'e5']);
      expect(cubit.state.position.turn, Side.white);
    },
  );

  blocTest<FreeBoardCubit, FreeBoardState>(
    'nova partida mantém o tabuleiro virado e o lado do jogador',
    build: () => FreeBoardCubit(playerSide: Side.white),
    act: (cubit) {
      cubit
        ..flip()
        ..play(NormalMove.fromUci('e2e4'))
        ..newGame();
    },
    skip: 2,
    verify: (cubit) {
      expect(cubit.state.moves, isEmpty);
      expect(cubit.state.orientation, Side.black);
      expect(cubit.state.playerSide, Side.white);
    },
  );
}
