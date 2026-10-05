import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/catalog/view_models/catalog_cubit.dart';

import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';

void main() {
  late FakeTrainingRepository training;

  CatalogCubit build() => CatalogCubit(
    FakePositionsRepository(),
    training,
    FakeProgressRepository(),
  );

  setUp(() => training = FakeTrainingRepository());

  test('carrega as categorias com o filtro gravado', () async {
    training.filter = GoalFilter.draw;
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.filter, GoalFilter.draw);
    expect(cubit.state.categories?.map((c) => c.key), ['basic', 'rookPawn']);
    expect(cubit.state.positions, isNull);
    expect(cubit.state.sections, isNull);
  });

  test(
    'com a categoria, carrega as posições de todos os finais dela',
    () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.load(category: 'basic');

      expect(cubit.state.positions?.map((p) => p.id), [
        'basic.queen.0001',
        'basic.rook.0001',
      ]);
      expect(cubit.state.sections?.map((s) => s.subcategory), [
        'queen',
        'rook',
      ]);
      expect(cubit.state.sections?.every((s) => s.expanded), isTrue);
    },
  );

  test('filtrar "defender" deixa só as posições de empate e grava', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(category: 'rookPawn');

    await cubit.setFilter(GoalFilter.draw);

    expect(cubit.state.visiblePositions?.map((p) => p.goal), [
      PositionGoal.draw,
    ]);
    expect(training.filter, GoalFilter.draw);
  });

  test('final sem posição para o filtro sai das seções', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(category: 'basic');

    await cubit.setFilter(GoalFilter.draw);

    expect(cubit.state.sections, isEmpty);
  });

  test('fechar uma seção e abrir de novo', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(category: 'basic');

    cubit.toggleSection('queen');

    expect(cubit.state.sections?.map((s) => s.expanded), [false, true]);

    cubit.toggleSection('queen');

    expect(cubit.state.sections?.map((s) => s.expanded), [true, true]);
  });

  test('a contagem da categoria segue o filtro', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load();

    final basic = cubit.state.categories!.first;
    expect(basic.count(GoalFilter.all), 2);
    expect(basic.count(GoalFilter.win), 2);
    expect(basic.count(GoalFilter.draw), 0);
  });
}
