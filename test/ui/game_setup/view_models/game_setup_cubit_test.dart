import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';

import '../../../../testing/fakes/fake_training_repository.dart';

void main() {
  late FakeTrainingRepository training;

  GameSetupCubit build({String fen = '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1'}) {
    return GameSetupCubit(
      training,
      position: GameRules.fromFen(fen)!,
      goal: PositionGoal.win,
    );
  }

  setUp(() => training = FakeTrainingRepository());

  test('o jogador começa com o lado que joga na posição', () {
    expect(build().state.userSide, Side.white);
    expect(
      build(fen: '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1').state.userSide,
      Side.black,
    );
  });

  test('carrega a última configuração gravada', () async {
    training.setup = const GameSetup(clock: false);
    final cubit = build();
    addTearDown(cubit.close);
    expect(cubit.state.canStart, isFalse);

    await cubit.load();

    expect(cubit.state.setup.clock, isFalse);
    expect(cubit.state.canStart, isTrue);
  });

  test(
    '3+2 para o jogador e 1+0 para o adversário: cada relógio no seu lado',
    () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.setUserTime(minutes: 3, increment: 2);
      await cubit.setOpponentTime(minutes: 1, increment: 0);

      expect(cubit.state.clockCodes, (white: '180+2', black: '60+0'));
      cubit.setUserSide(Side.black);
      expect(cubit.state.clockCodes, (white: '60+0', black: '180+2'));
      expect(
        training.setup.userTime,
        const TimeControl(
          initial: Duration(minutes: 3),
          increment: Duration(seconds: 2),
        ),
      );
    },
  );

  test('tempo zero bloqueia o começo', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setOpponentTime(minutes: 0);

    expect(cubit.state.hasZeroTime, isTrue);
    expect(cubit.state.canStart, isFalse);

    await cubit.setClock(enabled: false);
    expect(cubit.state.canStart, isTrue);
    expect(cubit.state.clockCodes, (white: null, black: null));
  });

  test('os tempos ficam dentro dos limites', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.setUserTime(minutes: 999, increment: -4);

    expect(
      cubit.state.setup.userTime.initial.inMinutes,
      SetupLimits.maxMinutes,
    );
    expect(cubit.state.setup.userTime.increment, Duration.zero);
  });
}
