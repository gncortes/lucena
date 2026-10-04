import 'package:bloc_test/bloc_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/use_cases/clock_engine.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';

void main() {
  late FakeNow now;
  late FakeHapticsRepository haptics;
  late FakeSettingsRepository settings;
  late FakeOngoingGameRepository games;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    haptics = FakeHapticsRepository();
    settings = FakeSettingsRepository();
    games = FakeOngoingGameRepository();
  });

  /// Partida nova. Com [start] nulo, a tela que continua a partida gravada.
  FreeBoardCubit build({
    Position? start = GameRules.initial,
    Side? playerSide,
    ClockConfig? clock,
  }) {
    return FreeBoardCubit(
      now: now,
      haptics: haptics,
      settings: settings,
      games: games,
      start: start,
      playerSide: playerSide,
      clock: clock,
    );
  }

  const fiveSeconds = TimeControl(initial: Duration(seconds: 5));
  const threeTwo = TimeControl(
    initial: Duration(minutes: 3),
    increment: Duration(seconds: 2),
  );
  const oneZero = TimeControl(initial: Duration(minutes: 1));

  // O aviso de vibração lê as preferências antes de vibrar.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  void playAll(FreeBoardCubit cubit, List<String> ucis) {
    for (final uci in ucis) {
      cubit.play(NormalMove.fromUci(uci));
    }
  }

  test('abre na posição inicial, sem lances', () {
    final state = build().state;

    expect(state.position, GameRules.initial);
    expect(state.moves, isEmpty);
    expect(state.lastMove, isNull);
    expect(state.end, isNull);
  });

  blocTest<FreeBoardCubit, FreeBoardState>(
    'e4 e5 Cf3: a lista ganha os três lances e a vez passa',
    build: build,
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
    build: build,
    act: (cubit) => playAll(cubit, ['e2e5', 'e7e5']),
    expect: () => <FreeBoardState>[],
  );

  blocTest<FreeBoardCubit, FreeBoardState>(
    'mate do pastor termina a partida e trava o tabuleiro',
    build: build,
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
    build: build,
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
    final cubit = build(start: start);
    addTearDown(cubit.close);

    cubit.play(NormalMove.fromUci('a7a8n'));
    expect(cubit.state.moves, ['a8=N']);

    cubit.newGame();
    expect(cubit.state.position, start);
    expect(cubit.state.moves, isEmpty);
  });

  test('sem lado escolhido, o jogador move os dois e vê pelas brancas', () {
    final state = build().state;

    expect(state.playerSide, isNull);
    expect(state.orientation, Side.white);
  });

  test('jogando de pretas, o tabuleiro abre virado para as pretas', () {
    final state = build(playerSide: Side.black).state;

    expect(state.playerSide, Side.black);
    expect(state.orientation, Side.black);
  });

  blocTest<FreeBoardCubit, FreeBoardState>(
    'virar o tabuleiro inverte a orientação e não mexe na partida',
    build: build,
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
    build: () => build(playerSide: Side.white),
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

  group('relógio', () {
    test('sem relógio, a partida não tem tempo e o tique não faz nada', () {
      final cubit = build();
      addTearDown(cubit.close);

      now.advance(const Duration(hours: 1));
      cubit.tick();

      expect(cubit.state.clock, isNull);
      expect(cubit.state.end, isNull);
    });

    test('abre com o tempo de cada lado e o relógio de quem joga correndo', () {
      final cubit = build(
        clock: const ClockConfig(white: oneZero, black: threeTwo),
      );
      addTearDown(cubit.close);

      expect(cubit.state.clock?.running, Side.white);
      expect(cubit.state.whiteTime, const Duration(minutes: 1));
      expect(cubit.state.blackTime, const Duration(minutes: 3));
    });

    test('o tique desconta só de quem está na vez', () {
      final cubit = build(clock: ClockConfig.same(threeTwo));
      addTearDown(cubit.close);

      now.advance(const Duration(seconds: 12, milliseconds: 400));
      cubit.tick();

      expect(cubit.state.whiteTime, const Duration(minutes: 2, seconds: 47));
      expect(cubit.state.blackTime, const Duration(minutes: 3));
    });

    blocTest<FreeBoardCubit, FreeBoardState>(
      'tiques dentro do mesmo segundo não mudam o estado',
      build: () => build(clock: ClockConfig.same(threeTwo)),
      act: (cubit) {
        now.advance(const Duration(milliseconds: 300));
        cubit.tick();
        now.advance(const Duration(milliseconds: 300));
        cubit.tick();
        now.advance(const Duration(milliseconds: 300));
        cubit.tick();
      },
      verify: (cubit) => expect(
        cubit.state.whiteTime,
        const Duration(minutes: 2, seconds: 59),
      ),
      expect: () => hasLength(1),
    );

    test('incremento soma 2 s após o lance e o relógio passa a vez', () {
      final cubit = build(clock: ClockConfig.same(threeTwo));
      addTearDown(cubit.close);

      cubit.play(NormalMove.fromUci('e2e4'));

      expect(cubit.state.whiteTime, const Duration(minutes: 3, seconds: 2));
      expect(cubit.state.clock?.running, Side.black);
    });

    test('tempos diferentes por lado: cada um ganha o seu incremento', () {
      final cubit = build(
        clock: const ClockConfig(white: oneZero, black: threeTwo),
      );
      addTearDown(cubit.close);

      playAll(cubit, ['e2e4', 'e7e5']);

      expect(cubit.state.whiteTime, const Duration(minutes: 1));
      expect(cubit.state.blackTime, const Duration(minutes: 3, seconds: 2));
    });

    test('tempo esgotado: a bandeira cai e o outro lado vence', () {
      final cubit = build(clock: ClockConfig.same(fiveSeconds));
      addTearDown(cubit.close);

      now.advance(const Duration(seconds: 5));
      cubit.tick();

      expect(
        cubit.state.end,
        const GameEnd(GameEndReason.timeout, winner: Side.black),
      );
      expect(cubit.state.whiteTime, Duration.zero);
      expect(cubit.state.clock?.running, isNull);
    });

    test('lance depois do tempo esgotado não entra', () {
      final cubit = build(clock: ClockConfig.same(fiveSeconds));
      addTearDown(cubit.close);

      now.advance(const Duration(seconds: 6));
      cubit.play(NormalMove.fromUci('e2e4'));

      expect(cubit.state.moves, isEmpty);
      expect(cubit.state.end?.reason, GameEndReason.timeout);
    });

    test('bandeira contra quem não tem material para dar mate é empate', () {
      final cubit = build(
        start: GameRules.fromFen('k7/8/8/8/8/8/P7/K7 w - - 0 1')!,
        clock: ClockConfig.same(fiveSeconds),
      );
      addTearDown(cubit.close);

      now.advance(const Duration(seconds: 5));
      cubit.tick();

      expect(
        cubit.state.end,
        const GameEnd(GameEndReason.timeoutVsInsufficientMaterial),
      );
    });

    test('o mate para o relógio', () {
      final cubit = build(
        start: GameRules.fromFen(
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
        )!,
        clock: ClockConfig.same(fiveSeconds),
      );
      addTearDown(cubit.close);

      cubit.play(NormalMove.fromUci('h5f7'));
      now.advance(const Duration(minutes: 1));
      cubit.tick();

      expect(cubit.state.end?.reason, GameEndReason.checkmate);
      expect(cubit.state.clock?.running, isNull);
      expect(cubit.state.blackTime, const Duration(seconds: 5));
    });

    test('nova partida recomeça o relógio com o mesmo tempo', () {
      final cubit = build(clock: ClockConfig.same(threeTwo));
      addTearDown(cubit.close);
      cubit.play(NormalMove.fromUci('e2e4'));
      now.advance(const Duration(seconds: 30));

      cubit.newGame();

      expect(cubit.state.moves, isEmpty);
      expect(cubit.state.whiteTime, const Duration(minutes: 3));
      expect(cubit.state.blackTime, const Duration(minutes: 3));
      expect(cubit.state.clock?.running, Side.white);
      expect(cubit.state.clock?.turnStartedAt, now());
    });

    test('nova partida depois da bandeira limpa o fim por tempo', () {
      final cubit = build(clock: ClockConfig.same(fiveSeconds));
      addTearDown(cubit.close);
      now.advance(const Duration(seconds: 5));
      cubit.tick();

      cubit.newGame();

      expect(cubit.state.end, isNull);
      expect(cubit.state.whiteTime, const Duration(seconds: 5));
    });

    test('escolher um relógio recomeça a partida com ele; nulo tira', () {
      final cubit = build();
      addTearDown(cubit.close);
      cubit.play(NormalMove.fromUci('e2e4'));

      cubit.newGameWithClock(
        const ClockConfig(white: oneZero, black: threeTwo),
      );
      expect(cubit.state.moves, isEmpty);
      expect(cubit.state.whiteTime, const Duration(minutes: 1));
      expect(cubit.state.blackTime, const Duration(minutes: 3));

      cubit.newGameWithClock(null);
      expect(cubit.state.clock, isNull);
    });

    test(
      'vibra uma vez quando o tempo de quem joga fica abaixo de 10 s',
      () async {
        final cubit = build(
          clock: ClockConfig.same(
            const TimeControl(initial: Duration(seconds: 15)),
          ),
        );
        addTearDown(cubit.close);

        now.advance(const Duration(seconds: 4));
        cubit.tick();
        await settle();
        expect(haptics.lowTimeCalls, 0);

        now.advance(const Duration(seconds: 2));
        cubit.tick();
        now.advance(const Duration(seconds: 1));
        cubit.tick();
        await settle();
        expect(haptics.lowTimeCalls, 1);
      },
    );

    test('com a vibração desligada nas preferências, não vibra', () async {
      settings.settings = const AppSettings(
        clock: ClockSettings(lowTimeVibration: false),
      );
      final cubit = build(clock: ClockConfig.same(fiveSeconds));
      addTearDown(cubit.close);

      now.advance(const Duration(seconds: 1));
      cubit.tick();
      await settle();

      expect(haptics.lowTimeCalls, 0);
    });

    test('jogando de um lado só, o relógio do adversário não vibra', () async {
      final cubit = build(
        playerSide: Side.black,
        clock: ClockConfig.same(fiveSeconds),
      );
      addTearDown(cubit.close);

      now.advance(const Duration(seconds: 1));
      cubit.tick();
      await settle();
      expect(haptics.lowTimeCalls, 0);

      cubit.play(NormalMove.fromUci('e2e4'));
      now.advance(const Duration(seconds: 1));
      cubit.tick();
      await settle();
      expect(haptics.lowTimeCalls, 1);
    });
  });

  group('gravação e restauração', () {
    final startFen = GameRules.initial.fen;

    test('cada lance grava a partida', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open();

      playAll(cubit, ['e2e4', 'e7e5']);
      await cubit.open();

      expect(
        games.snapshot,
        GameSnapshot(startFen: startFen, moves: const ['e2e4', 'e7e5']),
      );
    });

    test('virar o tabuleiro e o relógio também são gravados', () async {
      final cubit = build(clock: ClockConfig.same(threeTwo));
      addTearDown(cubit.close);

      cubit
        ..flip()
        ..play(NormalMove.fromUci('e2e4'));
      await cubit.open();

      expect(games.snapshot?.orientation, Side.black);
      expect(games.snapshot?.clock, cubit.state.clock);
      expect(games.snapshot?.clock?.turnStartedAt, now());
    });

    test('partida terminada por mate sai da gravação', () async {
      final cubit = build(
        start: GameRules.fromFen(
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4',
        ),
      );
      addTearDown(cubit.close);
      await cubit.open();
      expect(games.snapshot, isNotNull);

      cubit.play(NormalMove.fromUci('h5f7'));
      await cubit.open();

      expect(games.snapshot, isNull);
    });

    test('partida terminada por tempo sai da gravação', () async {
      final cubit = build(clock: ClockConfig.same(fiveSeconds));
      addTearDown(cubit.close);
      await cubit.open();

      now.advance(const Duration(seconds: 5));
      cubit.tick();
      await cubit.open();

      expect(games.snapshot, isNull);
    });

    test('nova partida depois do fim volta a ser gravada', () async {
      final cubit = build(clock: ClockConfig.same(fiveSeconds));
      addTearDown(cubit.close);
      now.advance(const Duration(seconds: 5));
      cubit
        ..tick()
        ..newGame();
      await cubit.open();

      expect(games.snapshot?.moves, isEmpty);
      expect(games.snapshot?.clock?.running, Side.white);
    });

    test('sem partida gravada, a tela começa uma do início', () async {
      final cubit = build(start: null);
      addTearDown(cubit.close);
      expect(cubit.state.ready, isFalse);

      await cubit.open();

      expect(cubit.state.ready, isTrue);
      expect(cubit.state.position, GameRules.initial);
      expect(games.snapshot, GameSnapshot(startFen: startFen));
    });

    test('antes de a partida ser lida, lances são ignorados', () {
      final cubit = build(start: null);
      addTearDown(cubit.close);

      cubit
        ..play(NormalMove.fromUci('e2e4'))
        ..flip()
        ..newGame();

      expect(cubit.state.moves, isEmpty);
      expect(cubit.state.ready, isFalse);
      expect(games.saved, isEmpty);
    });

    test(
      'reabrir: mesma posição, mesma lista e tabuleiro virado igual',
      () async {
        games.snapshot = GameSnapshot(
          startFen: startFen,
          moves: const ['e2e4', 'e7e5', 'g1f3'],
          orientation: Side.black,
          playerSide: Side.black,
        );
        final cubit = build(start: null);
        addTearDown(cubit.close);

        await cubit.open();

        expect(cubit.state.moves, ['e4', 'e5', 'Nf3']);
        expect(cubit.state.ucis, ['e2e4', 'e7e5', 'g1f3']);
        expect(
          cubit.state.position.fen,
          'rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2',
        );
        expect(cubit.state.lastMove, NormalMove.fromUci('g1f3'));
        expect(cubit.state.orientation, Side.black);
        expect(cubit.state.playerSide, Side.black);
        expect(cubit.state.start, GameRules.initial);
      },
    );

    test(
      'reabrir com o relógio correndo: o tempo fechado é descontado',
      () async {
        final first = build(clock: ClockConfig.same(threeTwo));
        first.play(NormalMove.fromUci('e2e4'));
        await first.open();
        await first.close();

        // O app ficou fechado por 20 s, na vez das pretas.
        now.advance(const Duration(seconds: 20));
        final cubit = build(start: null);
        addTearDown(cubit.close);
        await cubit.open();

        expect(cubit.state.moves, ['e4']);
        expect(cubit.state.whiteTime, const Duration(minutes: 3, seconds: 2));
        expect(cubit.state.blackTime, const Duration(minutes: 2, seconds: 40));
        expect(cubit.state.clock?.running, Side.black);
      },
    );

    test(
      'o tempo acabou com o app fechado: ao reabrir, fim por tempo',
      () async {
        final first = build(clock: ClockConfig.same(fiveSeconds));
        await first.open();
        await first.close();

        now.advance(const Duration(minutes: 1));
        final cubit = build(start: null);
        addTearDown(cubit.close);
        await cubit.open();

        expect(
          cubit.state.end,
          const GameEnd(GameEndReason.timeout, winner: Side.black),
        );
        expect(games.snapshot, isNull);
      },
    );

    test(
      'sair da tela para o relógio e marca a partida como fora da tela',
      () async {
        final cubit = build(clock: ClockConfig.same(threeTwo));
        addTearDown(cubit.close);
        now.advance(const Duration(seconds: 10));

        await cubit.leave();

        expect(games.snapshot?.onScreen, isFalse);
        expect(games.snapshot?.clock?.running, isNull);
        expect(
          games.snapshot?.clock?.white,
          const Duration(minutes: 2, seconds: 50),
        );
      },
    );

    test('depois de sair da tela, nada mais mexe na partida gravada', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.leave();

      cubit
        ..play(NormalMove.fromUci('e2e4'))
        ..flip()
        ..newGame();
      await settle();

      expect(cubit.state.moves, isEmpty);
      expect(cubit.state.orientation, Side.white);
      expect(games.snapshot?.onScreen, isFalse);
      expect(games.saved, hasLength(1));
    });

    test('voltar depois de sair: o relógio retoma de onde parou', () async {
      final first = build(clock: ClockConfig.same(threeTwo));
      now.advance(const Duration(seconds: 10));
      await first.leave();
      await first.close();

      // Horas depois, o tempo parado não foi descontado.
      now.advance(const Duration(hours: 3));
      final cubit = build(start: null);
      addTearDown(cubit.close);
      await cubit.open();

      expect(cubit.state.whiteTime, const Duration(minutes: 2, seconds: 50));
      expect(cubit.state.clock?.running, Side.white);
      expect(games.snapshot?.onScreen, isTrue);

      now.advance(const Duration(seconds: 5));
      cubit.tick();
      expect(cubit.state.whiteTime, const Duration(minutes: 2, seconds: 45));
    });

    test(
      'gravação que não fecha com as regras é trocada por partida nova',
      () async {
        games.snapshot = GameSnapshot(
          startFen: startFen,
          moves: const ['e2e4', 'e2e4'],
        );
        final cubit = build(start: null);
        addTearDown(cubit.close);

        await cubit.open();

        expect(cubit.state.moves, isEmpty);
        expect(cubit.state.position, GameRules.initial);
        expect(games.snapshot, GameSnapshot(startFen: startFen));
      },
    );

    test('partida nova numa posição preparada substitui a gravada', () async {
      games.snapshot = GameSnapshot(startFen: startFen, moves: const ['e2e4']);
      const fen = '8/P6k/8/8/8/8/8/K7 w - - 0 1';
      final cubit = build(start: GameRules.fromFen(fen));
      addTearDown(cubit.close);

      await cubit.open();

      expect(games.snapshot, const GameSnapshot(startFen: fen));
    });

    test(
      'o relógio gravado é o mesmo da regra: instantes, não tiques',
      () async {
        final cubit = build(clock: ClockConfig.same(threeTwo));
        addTearDown(cubit.close);
        await cubit.open();
        final saved = games.snapshot!.clock!;

        // Nenhum tique: só a conta a partir do instante gravado.
        final later = now().add(const Duration(seconds: 33));
        expect(
          ClockEngine.remaining(saved, Side.white, later),
          const Duration(minutes: 2, seconds: 27),
        );
      },
    );
  });
}
