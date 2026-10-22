import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/featured/featured_alerts_repository.dart';
import 'package:lucena/data/repositories/featured/featured_progress_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  LocalFeaturedProgressRepository reopen() =>
      LocalFeaturedProgressRepository(PreferencesService());

  test('jogados sobrevivem a reabrir o repositório e não repetem', () async {
    expect(await reopen().played(), isEmpty);
    await reopen().markPlayed('b');
    await reopen().markPlayed('a');
    await reopen().markPlayed('a');
    expect(await reopen().played(), {'a', 'b'});
  });

  test('a escolha do adversário e do relógio é guardada por final', () async {
    expect(await reopen().choice('a'), isNull);
    const choice = FeaturedChoice(
      opponent: OpponentKind.maia,
      level: 1800,
      clock: '300+0',
    );
    await reopen().saveChoice('a', choice);
    expect(await reopen().choice('a'), choice);
    expect(await reopen().choice('b'), isNull);
    await reopen().saveChoice(
      'a',
      const FeaturedChoice(opponent: OpponentKind.stockfish),
    );
    final again = await reopen().choice('a');
    expect(again!.opponent, OpponentKind.stockfish);
    expect(again.level, isNull);
    expect(again.clock, isNull);
  });

  test('sem canal de aviso, nada está disponível nem ligado', () async {
    const alerts = NoFeaturedAlertsRepository();
    expect(alerts.available, isFalse);
    await alerts.setEnabled(value: true);
    await alerts.setTournamentEnabled('t', value: true);
    expect(await alerts.enabled(), isFalse);
    expect(await alerts.tournamentEnabled('t'), isFalse);
  });
}
