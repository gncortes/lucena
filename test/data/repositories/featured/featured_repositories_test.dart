import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/featured/featured_alerts_repository.dart';
import 'package:lucena/data/repositories/featured/featured_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
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

  test(
    'o aviso de finais novos começa desligado e sobrevive a reabrir',
    () async {
      LocalFeaturedAlertsRepository reopenAlerts() =>
          LocalFeaturedAlertsRepository(PreferencesService());
      expect(await reopenAlerts().enabled(), isFalse);
      await reopenAlerts().setEnabled(value: true);
      expect(await reopenAlerts().enabled(), isTrue);
      await reopenAlerts().setEnabled(value: false);
      expect(await reopenAlerts().enabled(), isFalse);
    },
  );

  group('catálogo (H-DES-07, gap 4)', () {
    test('arquivo ausente ou ilegível é erro, não lista vazia', () async {
      final missing = AssetFeaturedRepository(_BrokenAssets('{ruim'));
      await expectLater(missing.catalog(), throwsA(anything));
      final absent = AssetFeaturedRepository(_BrokenAssets(null));
      await expectLater(absent.catalog(), throwsA(anything));
    });

    test('falha não fica em cache: tentar de novo lê o arquivo', () async {
      final assets = _BrokenAssets(null);
      final repository = AssetFeaturedRepository(assets);
      await expectLater(repository.catalog(), throwsA(anything));
      assets.text = '{"tournaments": [], "finals": []}';
      final catalog = await repository.catalog();
      expect(catalog.finals, isEmpty);
    });
  });
}

class _BrokenAssets extends AssetService {
  _BrokenAssets(this.text);

  String? text;

  @override
  Future<String> loadString(String path) async {
    final value = text;
    if (value == null) throw StateError('sem arquivo');
    return value;
  }
}
