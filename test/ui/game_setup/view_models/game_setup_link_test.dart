import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';

import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';

const _fen = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1';

GameSetupCubit _build(FakeTrainingRepository training, {ChallengeLink? link}) =>
    GameSetupCubit(
      training,
      progress: FakeProgressRepository(),
      profile: FakeProfileRepository(),
      position: GameRules.fromFen(_fen)!,
      goal: PositionGoal.win,
      positionId: 'kq-k',
      link: link,
    );

void main() {
  test(
    'o desafio da configuração leva posição, lado, Maia e relógio',
    () async {
      final training = FakeTrainingRepository(
        setup: GameSetup(
          maiaLevel: 1400,
          userTime: TimeControl.tryParse('300+0')!,
          opponentTime: TimeControl.tryParse('300+0')!,
        ),
      );
      final cubit = _build(training);
      addTearDown(cubit.close);
      await cubit.load();
      final link = cubit.state.challenge;
      expect(link.fen, _fen);
      expect(link.positionId, 'kq-k');
      expect(link.userSide, Side.white);
      expect(link.opponent, OpponentKind.maia);
      expect(link.level, 1400);
      expect(link.clock!.code, '300+0');
      expect(link.locked, isFalse);
    },
  );

  test(
    'sem relógio o desafio não leva relógio; Stockfish não leva nível',
    () async {
      final cubit = _build(
        FakeTrainingRepository(
          setup: const GameSetup(
            clock: false,
            opponent: OpponentKind.stockfish,
          ),
        ),
      );
      addTearDown(cubit.close);
      await cubit.load();
      final link = cubit.state.challenge;
      expect(link.clock, isNull);
      expect(link.opponent, OpponentKind.stockfish);
      expect(link.level, isNull);
    },
  );

  test('aberta por link, a configuração vem dele e não é gravada', () async {
    final training = FakeTrainingRepository();
    final link = ChallengeLink(
      fen: _fen,
      userSide: Side.black,
      opponent: OpponentKind.stockfish,
      clock: TimeControl.tryParse('180+2'),
    );
    final cubit = _build(training, link: link);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.fromLink, isTrue);
    expect(cubit.state.userSide, Side.black);
    expect(cubit.state.setup.opponent, OpponentKind.stockfish);
    expect(cubit.state.setup.clock, isTrue);
    expect(cubit.state.setup.userTime.code, '180+2');
    expect(training.setup, const GameSetup());
    // A partida que abre sabe que veio de um link.
    expect(cubit.state.gameRoute, contains('link=1'));
  });

  test('uma partida normal não leva a marca de link', () async {
    final cubit = _build(FakeTrainingRepository());
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.gameRoute, isNot(contains('link=')));
  });
}
