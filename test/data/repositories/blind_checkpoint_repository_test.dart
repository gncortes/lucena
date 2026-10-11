import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/blind/blind_checkpoint_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/blind_checkpoint.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  LocalBlindCheckpointRepository reopen() =>
      LocalBlindCheckpointRepository(PreferencesService());
  test('checkpoint survives repository reconstruction and clears', () async {
    const checkpoint = BlindCheckpoint(
      setup: {'fen': 'start'},
      moves: ['e2e4'],
      state: {
        'phase': 'proposing',
        'proposal': 'g1f3',
        'speechStart': 4,
        'whiteMs': 1000,
      },
    );
    await reopen().save(checkpoint);
    final restored = await reopen().load();
    expect(restored!.toJson(), checkpoint.toJson());
    await reopen().clear();
    expect(await reopen().load(), isNull);
  });
  test('invalid JSON/version is discarded', () async {
    for (final text in ['invalid', '{"version":2}']) {
      await PreferencesService().setString(
        LocalBlindCheckpointRepository.key,
        text,
      );
      expect(await reopen().load(), isNull);
      expect(
        await PreferencesService().getString(
          LocalBlindCheckpointRepository.key,
        ),
        isNull,
      );
    }
  });
}
