import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/use_cases/position_validation.dart';
import 'package:lucena/ui/custom_position/view_models/custom_position_cubit.dart';

import '../../../../testing/fakes/fake_training_repository.dart';

void main() {
  late FakeTrainingRepository training;

  setUp(() => training = FakeTrainingRepository());

  Future<CustomPositionCubit> build() async {
    final cubit = CustomPositionCubit(training);
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  test('sem rascunho, começa com os dois reis', () async {
    final cubit = await build();

    expect(cubit.state.fen, CustomPositionCubit.startFen);
    expect(cubit.state.board, CustomPositionCubit.startBoard);
    // Só os reis: não há partida a jogar.
    expect(cubit.state.problem, PositionProblem.alreadyOver);
  });

  test('o rascunho gravado volta', () async {
    training.draft = (
      fen: '4k3/8/8/8/8/8/4P3/4K3 b - - 0 1',
      goal: PositionGoal.draw,
    );
    final cubit = await build();

    expect(cubit.state.turn, Side.black);
    expect(cubit.state.goal, PositionGoal.draw);
    expect(cubit.state.position, isNotNull);
  });

  test('colar FEN válido: posição pronta, no lado certo, e gravada', () async {
    final cubit = await build();

    cubit.setFen('  8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1 ');

    expect(cubit.state.problem, isNull);
    expect(cubit.state.position?.turn, Side.black);
    expect(training.draft?.fen, '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');
  });

  test('FEN inválido: erro, e o editor fica com as últimas peças', () async {
    final cubit = await build();
    cubit.setFen('4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');

    cubit.setFen('4k3/8/8/8');

    expect(cubit.state.problem, PositionProblem.invalidFen);
    expect(cubit.state.position, isNull);
    expect(cubit.state.board, '4k3/8/8/8/8/8/4P3/4K3');
  });

  test('o editor muda as peças e o FEN acompanha', () async {
    final cubit = await build();

    cubit.setBoard('4k3/8/8/8/8/8/4P3/4K3');

    expect(cubit.state.fen, '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');
    expect(cubit.state.problem, isNull);

    cubit.setTurn(Side.black);
    expect(cubit.state.fen, '4k3/8/8/8/8/8/4P3/4K3 b - - 0 1');
  });

  test('limpar deixa só os dois reis, com a mesma vez', () async {
    final cubit = await build();
    cubit.setFen('4k3/8/8/8/8/8/4P3/4K3 b - - 0 1');

    cubit.clear();

    expect(cubit.state.fen, '${CustomPositionCubit.startBoard} b - - 0 1');
  });

  test('o objetivo escolhido é gravado junto', () async {
    final cubit = await build();

    cubit.setGoal(PositionGoal.draw);

    expect(cubit.state.goal, PositionGoal.draw);
    expect(training.draft?.goal, PositionGoal.draw);
  });
}
