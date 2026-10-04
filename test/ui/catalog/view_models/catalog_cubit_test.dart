import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/catalog/view_models/catalog_cubit.dart';

import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';

void main() {
  late FakeTrainingRepository training;

  CatalogCubit build() => CatalogCubit(FakePositionsRepository(), training);

  setUp(() => training = FakeTrainingRepository());

  test('carrega as categorias com o filtro gravado', () async {
    training.filter = GoalFilter.draw;
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.filter, GoalFilter.draw);
    expect(cubit.state.categories?.map((c) => c.key), ['basic', 'rookPawn']);
    expect(cubit.state.positions, isNull);
  });

  test('com a subcategoria, carrega as posições dela', () async {
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.load(subcategory: 'rookPawnVsRook');

    expect(cubit.state.positions, hasLength(2));
  });

  test('filtrar "defender" deixa só as posições de empate e grava', () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.load(subcategory: 'rookPawnVsRook');

    await cubit.setFilter(GoalFilter.draw);

    expect(cubit.state.visiblePositions?.map((p) => p.goal), [
      PositionGoal.draw,
    ]);
    expect(training.filter, GoalFilter.draw);
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
