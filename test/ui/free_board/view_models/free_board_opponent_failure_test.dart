import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';

import '../../../../testing/fakes/fake_draw_offer_repository.dart';
import '../../../../testing/fakes/fake_haptics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../../testing/fakes/fake_opponent_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';

/// H-PAR-18: o adversário falha no meio da partida. O relógio para na
/// primeira falha, o app tenta 3 vezes (2 s entre elas) e, na terceira, mostra
/// a folha de erro. Tentar novamente recomeça as 3 tentativas.
void main() {
  late FakeNow now;
  late FakeOngoingGameRepository games;
  late FakeOpponentRepository opponent;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    games = FakeOngoingGameRepository();
    opponent = FakeOpponentRepository(now: now);
  });

  final queenMate = GameRules.fromFen('8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1')!;
  const vsMachine = GameMode(
    opponent: OpponentKind.stockfish,
    userSide: Side.white,
    goal: PositionGoal.win,
    positionId: 'basic.queen.0001',
  );
  const fiveMinutes = TimeControl(initial: Duration(minutes: 5));

  FreeBoardCubit build({ClockConfig? clock}) => FreeBoardCubit(
    now: now,
    haptics: FakeHapticsRepository(),
    settings: FakeSettingsRepository(),
    games: games,
    opponent: opponent,
    progress: FakeProgressRepository(),
    draws: FakeDrawOfferRepository(),
    start: queenMate,
    clock: clock,
    mode: vsMachine,
  );

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  // Deixa passar o intervalo entre as tentativas e pede uma nova (a tela faz
  // isso a cada tique).
  Future<void> nextAttempt(FreeBoardCubit cubit) async {
    now.advance(const Duration(seconds: 2));
    cubit.tick();
    await settle();
  }

  test('1ª falha: o relógio para e nada é dito', () async {
    final cubit = build(clock: ClockConfig.same(fiveMinutes));
    addTearDown(cubit.close);
    await cubit.open();
    opponent.failTimes = 3;

    cubit.play(NormalMove.fromUci('c1g5'));
    await settle();

    expect(cubit.state.opponentError, isFalse);
    expect(cubit.state.clock!.running, isNull);
    final before = cubit.state.blackTime;
    now.advance(const Duration(seconds: 1));
    cubit.tick();
    expect(cubit.state.blackTime, before);
    expect(cubit.state.end, isNull);
  });

  test('3 falhas seguidas mostram a folha e o relógio não anda', () async {
    final cubit = build(clock: ClockConfig.same(fiveMinutes));
    addTearDown(cubit.close);
    await cubit.open();
    opponent.failTimes = 3;

    cubit.play(NormalMove.fromUci('c1g5'));
    await settle();
    expect(opponent.requests, hasLength(1));
    // Dentro dos 2 s nada é pedido de novo.
    now.advance(const Duration(seconds: 1));
    cubit.tick();
    await settle();
    expect(opponent.requests, hasLength(1));

    now.advance(const Duration(seconds: 1));
    cubit.tick();
    await settle();
    expect(opponent.requests, hasLength(2));
    expect(cubit.state.opponentError, isFalse);

    await nextAttempt(cubit);
    expect(opponent.requests, hasLength(3));
    expect(cubit.state.opponentError, isTrue);

    // Mesmo um minuto depois ninguém perde por tempo e nada é pedido.
    now.advance(const Duration(minutes: 10));
    cubit.tick();
    await settle();
    expect(opponent.requests, hasLength(3));
    expect(cubit.state.end, isNull);
    expect(cubit.state.clock!.running, isNull);
  });

  test('motor que devolve null conta como falha', () async {
    final cubit = build(clock: ClockConfig.same(fiveMinutes));
    addTearDown(cubit.close);
    await cubit.open();
    opponent.answerNullNext = true;

    cubit.play(NormalMove.fromUci('c1g5'));
    await settle();

    expect(cubit.state.clock!.running, isNull);
    // A segunda tentativa, com motor bom, joga.
    await nextAttempt(cubit);
    expect(cubit.state.moves, hasLength(2));
    expect(cubit.state.clock!.running, Side.white);
  });

  test('tentar novamente com o motor bom joga e o relógio volta', () async {
    final cubit = build(clock: ClockConfig.same(fiveMinutes));
    addTearDown(cubit.close);
    await cubit.open();
    opponent.failTimes = 3;
    cubit.play(NormalMove.fromUci('c1g5'));
    await settle();
    await nextAttempt(cubit);
    await nextAttempt(cubit);
    expect(cubit.state.opponentError, isTrue);

    cubit.retryOpponent();
    await settle();

    expect(cubit.state.opponentError, isFalse);
    expect(cubit.state.moves, hasLength(2));
    expect(cubit.state.clock!.running, Side.white);
  });

  test('tentar novamente recomeça as 3 tentativas', () async {
    final cubit = build(clock: ClockConfig.same(fiveMinutes));
    addTearDown(cubit.close);
    await cubit.open();
    opponent.failTimes = 6;
    cubit.play(NormalMove.fromUci('c1g5'));
    await settle();
    await nextAttempt(cubit);
    await nextAttempt(cubit);
    expect(cubit.state.opponentError, isTrue);

    cubit.retryOpponent();
    await settle();
    expect(cubit.state.opponentError, isFalse);
    await nextAttempt(cubit);
    expect(cubit.state.opponentError, isFalse);
    await nextAttempt(cubit);
    expect(cubit.state.opponentError, isTrue);
    expect(opponent.requests, hasLength(6));
  });

  test('sair mantém a partida gravada, com o relógio parado', () async {
    final cubit = build(clock: ClockConfig.same(fiveMinutes));
    addTearDown(cubit.close);
    await cubit.open();
    opponent.failTimes = 3;
    cubit.play(NormalMove.fromUci('c1g5'));
    await settle();
    await nextAttempt(cubit);
    await nextAttempt(cubit);

    await cubit.leave();

    final saved = await games.load();
    expect(saved, isNotNull);
    expect(saved!.moves, ['c1g5']);
    expect(saved.clock!.running, isNull);
  });

  test(
    'sem relógio a falha também espera o aviso depois de 3 tentativas',
    () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.open();
      opponent.failTimes = 3;

      cubit.play(NormalMove.fromUci('c1g5'));
      await settle();
      await nextAttempt(cubit);
      await nextAttempt(cubit);

      expect(cubit.state.opponentError, isTrue);
    },
  );
}
