import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// H-PAR-19: falta de espaço ao gravar. O fim de jogo não pode parar, a
/// tentativa só conta como gravada depois de gravar de fato e "Tentar
/// novamente" grava de novo e devolve o id da conclusão.
void main() {
  late FakeNow now;
  late FakeOngoingGameRepository games;
  late FakeProgressRepository progress;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 1, 1, 12));
    games = FakeOngoingGameRepository();
    progress = FakeProgressRepository();
  });

  // Mate em um: Dg1-g7#.
  final mateInOne = GameRules.fromFen('7k/5K2/8/8/8/8/8/6Q1 w - - 0 1')!;
  const vsMachine = GameMode(
    opponent: OpponentKind.stockfish,
    userSide: Side.white,
    goal: PositionGoal.win,
    positionId: 'basic.queen.0001',
  );

  FreeBoardCubit build() => FreeBoardCubit(
    now: now,
    haptics: FakeHapticsRepository(),
    settings: FakeSettingsRepository(),
    games: games,
    opponent: FakeOpponentRepository(now: now),
    progress: progress,
    draws: FakeDrawOfferRepository(),
    start: mateInOne,
    mode: vsMachine,
  );

  Future<FreeBoardCubit> opened() async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.open();
    return cubit;
  }

  test(
    'gravação da partida que falha não impede os lances nem o fim',
    () async {
      final cubit = await opened();
      games.failSave = 5;

      cubit.play(NormalMove.fromUci('g1g7'));
      await cubit.saved();

      expect(cubit.state.end, isNotNull);
      expect(cubit.state.recordFailed, isFalse);
      expect(progress.attempts, hasLength(1));
    },
  );

  test('tentativa que falha ao gravar avisa e não perde a partida', () async {
    final cubit = await opened();
    progress.failAddAttempt = 1;

    cubit.play(NormalMove.fromUci('g1g7'));
    await cubit.saved();

    expect(cubit.state.end, isNotNull);
    expect(cubit.state.recordFailed, isTrue);
    expect(await cubit.savedGameId(), isNull);
    expect(progress.attempts, isEmpty);
  });

  test('tentar novamente grava a tentativa e devolve o id', () async {
    final cubit = await opened();
    progress.failAddAttempt = 1;
    cubit.play(NormalMove.fromUci('g1g7'));
    await cubit.saved();

    await cubit.retryRecord();

    expect(cubit.state.recordFailed, isFalse);
    expect(progress.attempts, hasLength(1));
    expect(await cubit.savedGameId(), 1);
  });

  test('tentar novamente sem espaço ainda avisa, e uma 3ª vez grava', () async {
    final cubit = await opened();
    progress.failAddAttempt = 2;
    cubit.play(NormalMove.fromUci('g1g7'));
    await cubit.saved();

    await cubit.retryRecord();
    expect(cubit.state.recordFailed, isTrue);
    expect(progress.attempts, isEmpty);

    await cubit.retryRecord();
    expect(cubit.state.recordFailed, isFalse);
    expect(progress.attempts, hasLength(1));
  });

  test('voltar esconde o aviso; o resultado tenta gravar de novo', () async {
    final cubit = await opened();
    progress.failAddAttempt = 1;
    cubit.play(NormalMove.fromUci('g1g7'));
    await cubit.saved();

    cubit.dismissRecordError();
    expect(cubit.state.recordFailed, isFalse);

    // "Ver o resultado" pede o id: grava agora, sem duplicar.
    await cubit.retryRecord();
    expect(progress.attempts, hasLength(1));
    expect(await cubit.savedGameId(), 1);
  });
}
