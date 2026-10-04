import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/training_repository_local.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  LocalTrainingRepository reopen() =>
      LocalTrainingRepository(PreferencesService());

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('sem nada gravado: todas as posições, 5 min para cada lado', () async {
    expect(await reopen().loadCatalogFilter(), GoalFilter.all);
    expect(await reopen().loadSetup(), const GameSetup());
    expect(await reopen().loadCustomDraft(), isNull);
  });

  test('o filtro do catálogo volta ao reabrir', () async {
    await reopen().saveCatalogFilter(GoalFilter.draw);

    expect(await reopen().loadCatalogFilter(), GoalFilter.draw);
  });

  test('a última configuração de partida volta ao reabrir', () async {
    const setup = GameSetup(
      clock: false,
      userTime: TimeControl(
        initial: Duration(minutes: 3),
        increment: Duration(seconds: 2),
      ),
      opponentTime: TimeControl(initial: Duration(minutes: 1)),
    );
    await reopen().saveSetup(setup);

    expect(await reopen().loadSetup(), setup);
  });

  test('o rascunho da posição personalizada volta ao reabrir', () async {
    await reopen().saveCustomDraft((
      fen: '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1',
      goal: PositionGoal.draw,
    ));

    final draft = await reopen().loadCustomDraft();
    expect(draft?.fen, '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1');
    expect(draft?.goal, PositionGoal.draw);
  });
}
