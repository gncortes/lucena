import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/maia_timing.dart';
import 'package:lucena/domain/models/move_prediction.dart';
import 'package:lucena/ui/maia_debug/view_models/maia_debug_cubit.dart';

import '../../../testing/fakes/fake_maia_repository.dart';

void main() {
  late FakeMaiaRepository maia;

  setUp(() => maia = FakeMaiaRepository());

  test('abre no final de torre, nível 1400, sem previsão', () {
    final cubit = MaiaDebugCubit(maia);
    addTearDown(cubit.close);

    expect(cubit.state.fen, MaiaDebugState.defaultFen);
    expect(cubit.state.level, 1400);
    expect(cubit.state.status, MaiaDebugStatus.idle);
    expect(cubit.state.prediction, isNull);
  });

  blocTest<MaiaDebugCubit, MaiaDebugState>(
    'avaliar pede a posição no nível escolhido e mostra a previsão',
    build: () => MaiaDebugCubit(maia),
    act: (cubit) async {
      cubit.setLevel(2600);
      await cubit.evaluate();
    },
    skip: 1,
    expect: () => [
      const MaiaDebugState(level: 2600, status: MaiaDebugStatus.running),
      const MaiaDebugState(
        level: 2600,
        status: MaiaDebugStatus.done,
        prediction: FakeMaiaRepository.fallback,
      ),
    ],
    verify: (_) => expect(maia.requests, [(MaiaDebugState.defaultFen, 2600)]),
  );

  test('níveis diferentes mostram previsões diferentes', () async {
    const master = MovePrediction(
      moves: {'a1d1': 0.7, 'a1a4': 0.3},
      win: 0.96,
      draw: 0.04,
      loss: 0,
      elapsed: Duration(milliseconds: 90),
    );
    maia.byLevel[2600] = master;
    final cubit = MaiaDebugCubit(maia);
    addTearDown(cubit.close);

    cubit.setLevel(1000);
    await cubit.evaluate();
    final beginner = cubit.state.prediction;
    cubit.setLevel(2600);
    await cubit.evaluate();

    expect(beginner, FakeMaiaRepository.fallback);
    expect(cubit.state.prediction, master);
  });

  test('FEN inválido não chama o modelo', () async {
    final cubit = MaiaDebugCubit(maia);
    addTearDown(cubit.close);

    cubit.setFen('isto não é uma posição');
    await cubit.evaluate();

    expect(cubit.state.status, MaiaDebugStatus.invalidPosition);
    expect(cubit.state.prediction, isNull);
    expect(maia.requests, isEmpty);
  });

  test('se o modelo falha, a tela avisa e deixa tentar de novo', () async {
    final cubit = MaiaDebugCubit(maia);
    addTearDown(cubit.close);
    maia.failNext = true;

    await cubit.evaluate();
    expect(cubit.state.status, MaiaDebugStatus.failed);

    await cubit.evaluate();
    expect(cubit.state.status, MaiaDebugStatus.done);
  });

  group('medir a velocidade', () {
    Duration ms(int value) => Duration(milliseconds: value);

    test('faz dez contas, sem contar a que liga o modelo', () async {
      // A primeira conta (900 ms) é a que carrega o modelo.
      maia.elapsed.addAll([
        ms(900),
        for (var run = 0; run < 9; run++) ms(110),
        ms(300),
      ]);
      final cubit = MaiaDebugCubit(maia);
      addTearDown(cubit.close);
      cubit.setLevel(1800);

      await cubit.measure();

      expect(cubit.state.status, MaiaDebugStatus.done);
      expect(
        cubit.state.timing,
        MaiaTiming(
          runs: 10,
          median: ms(110),
          fastest: ms(110),
          slowest: ms(300),
        ),
      );
      expect(maia.requests, hasLength(MaiaDebugCubit.measureRuns + 1));
      expect(maia.requests.toSet(), {(MaiaDebugState.defaultFen, 1800)});
      // A previsão da posição aparece junto, como no avaliar.
      expect(cubit.state.prediction, isNotNull);
    });

    test('avaliar depois não apaga a medição', () async {
      final cubit = MaiaDebugCubit(maia);
      addTearDown(cubit.close);

      await cubit.measure();
      final timing = cubit.state.timing;
      await cubit.evaluate();

      expect(timing, isNotNull);
      expect(cubit.state.timing, timing);
    });

    test('FEN inválido não mede', () async {
      final cubit = MaiaDebugCubit(maia);
      addTearDown(cubit.close);

      cubit.setFen('isto não é uma posição');
      await cubit.measure();

      expect(cubit.state.status, MaiaDebugStatus.invalidPosition);
      expect(cubit.state.timing, isNull);
      expect(maia.requests, isEmpty);
    });

    test(
      'se o modelo falha no meio, a tela avisa e não inventa medição',
      () async {
        final cubit = MaiaDebugCubit(maia);
        addTearDown(cubit.close);
        maia.failNext = true;

        await cubit.measure();

        expect(cubit.state.status, MaiaDebugStatus.failed);
        expect(cubit.state.timing, isNull);
      },
    );
  });
}
