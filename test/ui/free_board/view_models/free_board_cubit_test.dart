import 'package:bloc_test/bloc_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/use_cases/clock_engine.dart';
import 'package:lucena/domain/use_cases/think_time_policy.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';

void main() {
  late FakeNow now;
  late FakeHapticsRepository haptics;
  late FakeSettingsRepository settings;
  late FakeOngoingGameRepository games;
  late FakeOpponentRepository opponent;
  late FakeProgressRepository progress;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    haptics = FakeHapticsRepository();
    settings = FakeSettingsRepository();
    games = FakeOngoingGameRepository();
    opponent = FakeOpponentRepository(now: now);
    progress = FakeProgressRepository();
  });

  /// Partida nova. Com [start] nulo, a tela que continua a partida gravada.
  FreeBoardCubit build({
    Position? start = GameRules.initial,
    Side? playerSide,
    ClockConfig? clock,
    GameMode mode = const GameMode(),
  }) {
    return FreeBoardCubit(
      now: now,
      haptics: haptics,
      settings: settings,
      games: games,
      opponent: opponent,
      progress: progress,
      start: start,
      playerSide: playerSide,
      clock: clock,
      mode: mode,
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
      FreeBoardState(
        start: GameRules.initial,
        position: GameRules.initial,
        startedAt: now(),
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
        GameSnapshot(
          startFen: startFen,
          moves: const ['e2e4', 'e7e5'],
          startedAt: now(),
        ),
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
      expect(
        games.snapshot,
        GameSnapshot(startFen: startFen, startedAt: now()),
      );
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
        expect(
          games.snapshot,
          GameSnapshot(startFen: startFen, startedAt: now()),
        );
      },
    );

    test('partida nova numa posição preparada substitui a gravada', () async {
      games.snapshot = GameSnapshot(startFen: startFen, moves: const ['e2e4']);
      const fen = '8/P6k/8/8/8/8/8/K7 w - - 0 1';
      final cubit = build(start: GameRules.fromFen(fen));
      addTearDown(cubit.close);

      await cubit.open();

      expect(games.snapshot, GameSnapshot(startFen: fen, startedAt: now()));
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

  group('contra a máquina', () {
    // Dama e rei contra rei: as brancas dão mate em poucos lances.
    final queenMate = GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1')!;
    const vsMachine = GameMode(
      opponent: OpponentKind.stockfish,
      userSide: Side.white,
      goal: PositionGoal.win,
      positionId: 'basic.queen.0001',
    );

    test('a máquina responde ao lance do jogador', () async {
      final cubit = build(start: queenMate, mode: vsMachine);
      addTearDown(cubit.close);
      await cubit.open();

      cubit.play(NormalMove.fromUci('c1g5'));
      await settle();

      expect(cubit.state.moves, hasLength(2));
      expect(cubit.state.position.turn, Side.white);
      expect(cubit.state.machineThinking, isFalse);
      expect(opponent.requests.single, contains(' b '));
    });

    test(
      'contra o Maia, o pedido leva o nível e as posições da partida',
      () async {
        final cubit = build(
          start: queenMate,
          mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1400),
        );
        addTearDown(cubit.close);
        await cubit.open();

        cubit.play(NormalMove.fromUci('c1g5'));
        await settle();
        cubit.play(NormalMove.fromUci('g5h6'));
        await settle();

        expect(opponent.kinds, [OpponentKind.maia, OpponentKind.maia]);
        expect(opponent.levels, [1400, 1400]);
        // Primeiro pedido: a posição inicial e a de depois do lance. Segundo:
        // mais a resposta da máquina e o novo lance.
        expect(opponent.histories.map((history) => history.length), [2, 4]);
        expect(opponent.histories.last.first.fen, queenMate.fen);
        expect(opponent.histories.last.last.fen, opponent.requests.last);
      },
    );

    test('a tentativa contra o Maia guarda o nível', () async {
      // Mate em um: Dc8.
      final mateInOne = GameRules.fromFen('k7/8/1K6/8/8/8/8/2Q5 w - - 0 1')!;
      final cubit = build(
        start: mateInOne,
        mode: vsMachine.copyWith(opponent: OpponentKind.maia, level: 1800),
      );
      addTearDown(cubit.close);
      await cubit.open();

      cubit.play(NormalMove.fromUci('c1c8'));
      await settle();

      expect(progress.attempts.single.opponent, OpponentKind.maia);
      expect(progress.attempts.single.opponentLevel, 1800);
    });

    test('o jogador só move o lado dele', () {
      final cubit = build(start: queenMate, mode: vsMachine);
      addTearDown(cubit.close);

      expect(cubit.state.playerSide, Side.white);
      expect(cubit.state.orientation, Side.white);
    });

    test('se a máquina começa, ela joga assim que a partida abre', () async {
      final blackToMove = GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 b - - 0 1')!;
      final cubit = build(start: blackToMove, mode: vsMachine);
      addTearDown(cubit.close);

      await cubit.open();
      await settle();

      expect(cubit.state.moves, hasLength(1));
      expect(cubit.state.position.turn, Side.white);
    });

    test('o relógio da máquina desconta o tempo que ela pensou', () async {
      final cubit = build(
        start: queenMate,
        mode: vsMachine,
        clock: ClockConfig.same(threeTwo),
      );
      addTearDown(cubit.close);
      await cubit.open();

      cubit.play(NormalMove.fromUci('c1g5'));
      await settle();

      final thought = opponent.thinkTimes.single;
      expect(thought, ThinkTimePolicy.max);
      // Ela pensou e ganhou o incremento.
      expect(
        cubit.state.blackTime,
        const Duration(minutes: 3, seconds: 2) - thought,
      );
    });

    test(
      'desistir na vez da máquina termina na hora e a resposta é ignorada',
      () async {
        final cubit = build(start: queenMate, mode: vsMachine);
        addTearDown(cubit.close);
        await cubit.open();
        opponent.hold();

        cubit.play(NormalMove.fromUci('c1g5'));
        await settle();
        expect(cubit.state.machineThinking, isTrue);

        cubit.resign();
        expect(
          cubit.state.end,
          const GameEnd(GameEndReason.resign, winner: Side.black),
        );

        opponent.release();
        await settle();
        expect(cubit.state.moves, ['Qg5']);
      },
    );

    test(
      'mate do jogador numa posição de ganhar: tentativa cumprida',
      () async {
        final mateInOne = GameRules.fromFen('3k4/8/3K4/8/8/8/8/7Q w - - 0 1')!;
        final cubit = build(start: mateInOne, mode: vsMachine);
        addTearDown(cubit.close);
        await cubit.open();

        cubit.play(NormalMove.fromUci('h1h8'));
        await cubit.open();

        expect(cubit.state.fulfilled, isTrue);
        expect(progress.attempts.single.outcome, AttemptOutcome.win);
        expect(progress.attempts.single.fulfilled, isTrue);
        expect(progress.attempts.single.positionId, 'basic.queen.0001');
      },
    );

    test('desistir numa posição de ganhar: tentativa não cumprida', () async {
      final cubit = build(start: queenMate, mode: vsMachine);
      addTearDown(cubit.close);
      await cubit.open();

      cubit.resign();
      await cubit.open();

      expect(cubit.state.fulfilled, isFalse);
      expect(progress.attempts.single.outcome, AttemptOutcome.loss);
    });

    test('empate numa posição de defender: cumprido', () async {
      // As brancas tomam o último peão: só os reis sobram.
      final cubit = build(
        start: GameRules.fromFen('k7/8/8/8/8/8/3p4/4K3 w - - 0 1')!,
        mode: const GameMode(
          opponent: OpponentKind.twoPlayers,
          userSide: Side.white,
          goal: PositionGoal.draw,
          positionId: 'pawn.pawnVsKing.0039',
        ),
      );
      addTearDown(cubit.close);
      await cubit.open();

      cubit.play(NormalMove.fromUci('e1d2'));
      await cubit.open();

      expect(cubit.state.end?.reason, GameEndReason.insufficientMaterial);
      expect(cubit.state.fulfilled, isTrue);
      expect(progress.attempts.single.outcome, AttemptOutcome.draw);
    });

    test(
      'jogar de novo: mesma posição e configuração, nova tentativa',
      () async {
        final cubit = build(
          start: queenMate,
          mode: vsMachine,
          clock: ClockConfig.same(threeTwo),
        );
        addTearDown(cubit.close);
        await cubit.open();
        cubit.resign();

        cubit.newGame();
        cubit.resign();
        await cubit.open();

        expect(cubit.state.start, queenMate);
        expect(cubit.state.mode, vsMachine);
        expect(cubit.state.clock?.config, ClockConfig.same(threeTwo));
        expect(progress.attempts, hasLength(2));
      },
    );

    test('a partida gravada leva lances, relógio, desafio e etapa', () async {
      final started = now();
      final cubit = build(
        start: GameRules.fromFen('3k4/8/3K4/8/8/8/8/7Q w - - 0 1')!,
        clock: ClockConfig.same(threeTwo),
        mode: vsMachine.copyWith(
          challengeId: '1000/basic.queen.0001',
          speedrunId: 'rung.1000',
          speedrunAttemptId: 3,
          speedrunStage: 1,
        ),
      );
      addTearDown(cubit.close);
      await cubit.open();

      now.advance(const Duration(seconds: 7));
      cubit.play(NormalMove.fromUci('h1h8'));
      await cubit.open();

      final game = progress.attempts.single;
      expect(game.startedAt, started);
      expect(game.playedAt, now());
      expect(game.startFen, '3k4/8/3K4/8/8/8/8/7Q w - - 0 1');
      expect(game.moves, ['h1h8']);
      expect(game.endReason, GameEndReason.checkmate);
      expect(game.userTime, threeTwo);
      expect(game.opponentTime, threeTwo);
      // Só o tempo que o relógio do jogador gastou (o incremento não conta).
      expect(game.userClock, const Duration(seconds: 7));
      expect(game.challengeId, '1000/basic.queen.0001');
      expect(game.speedrunAttemptId, 3);
      expect(game.speedrunStage, 1);
    });

    test('o tempo do jogador não inclui o que a máquina pensou', () async {
      final cubit = build(
        start: queenMate,
        clock: ClockConfig.same(threeTwo),
        mode: vsMachine,
      );
      addTearDown(cubit.close);
      await cubit.open();

      now.advance(const Duration(seconds: 4));
      cubit.play(NormalMove.fromUci('c1g5'));
      await settle();
      // A máquina já respondeu (o relógio dela andou o que ela pensou).
      expect(cubit.state.moves, hasLength(2));
      now.advance(const Duration(seconds: 6));
      cubit.resign();
      await cubit.open();

      expect(progress.attempts.single.userClock, const Duration(seconds: 10));
    });

    test('fora do treino nada é gravado no histórico', () async {
      final cubit = build(
        start: GameRules.fromFen('3k4/8/3K4/8/8/8/8/7Q w - - 0 1')!,
      );
      addTearDown(cubit.close);
      await cubit.open();

      cubit.play(NormalMove.fromUci('h1h8'));
      await cubit.open();

      expect(cubit.state.end?.reason, GameEndReason.checkmate);
      expect(progress.attempts, isEmpty);
    });

    test('reabrir na vez da máquina: a partida volta e ela joga', () async {
      final first = build(start: queenMate, mode: vsMachine);
      await first.open();
      opponent.hold();
      first.play(NormalMove.fromUci('c1g5'));
      await settle();
      // O app é fechado com a máquina pensando.
      await first.close();
      opponent.release();
      await settle();
      expect(games.snapshot?.moves, ['c1g5']);

      final cubit = build(start: null);
      addTearDown(cubit.close);
      await cubit.open();
      await settle();

      expect(cubit.state.mode, vsMachine);
      expect(cubit.state.moves, hasLength(2));
    });

    test(
      'voltar do segundo plano sem resposta pendente: a máquina pensa de novo',
      () async {
        final cubit = build(start: queenMate, mode: vsMachine);
        addTearDown(cubit.close);
        await cubit.open();
        opponent.failNext = true;

        cubit.play(NormalMove.fromUci('c1g5'));
        await settle();
        expect(cubit.state.moves, ['Qg5']);
        expect(cubit.state.machineThinking, isFalse);

        now.advance(const Duration(seconds: 3));
        cubit.resumed();
        await settle();

        expect(cubit.state.moves, hasLength(2));
      },
    );
  });

  group('empates automáticos contra a máquina', () {
    final rookEnding = GameRules.fromFen('8/8/8/4k3/8/8/8/R3K3 w - - 0 1')!;
    // Os reis vão e voltam: a posição inicial se repete a cada quatro lances.
    const shuffle = ['e1d1', 'e5d5', 'd1e1', 'd5e5'];

    GameMode training(PositionGoal goal) => GameMode(
      opponent: OpponentKind.stockfish,
      userSide: Side.white,
      goal: goal,
      positionId: 'rook.test',
    );

    // A máquina fica segurando a resposta: o teste joga os dois lados.
    FreeBoardCubit against(PositionGoal goal, {ClockConfig? clock}) {
      opponent.hold();
      final cubit = build(
        start: rookEnding,
        playerSide: Side.white,
        clock: clock,
        mode: training(goal),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    test('a terceira repetição empata e cumpre o objetivo de empatar', () {
      final cubit = against(PositionGoal.draw);

      playAll(cubit, shuffle);
      expect(cubit.state.end, isNull);
      expect(cubit.state.repetitions, 2);
      playAll(cubit, shuffle);

      expect(cubit.state.end, const GameEnd(GameEndReason.repetition));
      expect(cubit.state.outcome, AttemptOutcome.draw);
      expect(cubit.state.fulfilled, isTrue);
    });

    test('no objetivo de ganhar, repetir a posição não cumpre', () {
      final cubit = against(PositionGoal.win);

      playAll(cubit, [...shuffle, ...shuffle]);

      expect(cubit.state.end, const GameEnd(GameEndReason.repetition));
      expect(cubit.state.fulfilled, isFalse);
    });

    test('depois do empate, nenhum lance entra e o relógio para', () {
      final cubit = against(
        PositionGoal.draw,
        clock: ClockConfig.same(threeTwo),
      );

      playAll(cubit, [...shuffle, ...shuffle, 'e1d1']);

      expect(cubit.state.ucis, hasLength(8));
      expect(cubit.state.clock?.running, isNull);
    });

    test('50 lances sem captura nem lance de peão empatam', () {
      opponent.hold();
      final cubit = build(
        start: GameRules.fromFen('8/8/8/4k3/8/8/8/R3K3 w - - 98 60'),
        playerSide: Side.white,
        mode: training(PositionGoal.draw),
      );
      addTearDown(cubit.close);

      cubit.play(NormalMove.fromUci('a1a2'));
      expect(cubit.state.end, isNull);
      cubit.play(NormalMove.fromUci('e5d5'));

      expect(cubit.state.end, const GameEnd(GameEndReason.fiftyMoves));
      expect(cubit.state.fulfilled, isTrue);
    });

    test('a contagem de repetições sobrevive a fechar o app', () async {
      final first = against(PositionGoal.draw);
      playAll(first, shuffle);
      await settle();

      final cubit = build(start: null);
      addTearDown(cubit.close);
      await cubit.open();
      expect(cubit.state.repetitions, 2);
      playAll(cubit, shuffle);

      expect(cubit.state.end, const GameEnd(GameEndReason.repetition));
    });

    test('no tabuleiro livre, repetir a posição não encerra a partida', () {
      final cubit = build(start: rookEnding);
      addTearDown(cubit.close);

      playAll(cubit, [...shuffle, ...shuffle, ...shuffle]);

      expect(cubit.state.end, isNull);
      expect(cubit.state.ucis, hasLength(12));
    });
  });
}
