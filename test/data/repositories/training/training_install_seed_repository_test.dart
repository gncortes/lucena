import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/training_install_seed_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';

class _Preferences implements PreferencesService {
  String? saved;
  bool failRead = false;
  bool failWrite = false;
  @override
  Future<String?> getString(String key) async {
    if (failRead) throw StateError('read');
    return saved;
  }

  @override
  Future<void> setString(String key, String value) async {
    if (failWrite) throw StateError('write');
    saved = value;
  }

  @override
  Future<bool?> getBool(String key) async => null;
  @override
  Future<void> setBool(String key, {required bool value}) async {}
  @override
  Future<void> remove(String key) async {
    saved = null;
  }

  @override
  Future<void> clear() async {
    saved = null;
  }
}

void main() {
  test('leitura falha não substitui a semente da instalação', () async {
    final preferences = _Preferences()
      ..saved = 'existing-installation'
      ..failRead = true;
    var generated = 0;
    final repository = TrainingInstallSeedRepository(
      preferences,
      createSeed: () => 'new-${++generated}',
    );
    await expectLater(repository.load(), throwsStateError);
    expect(generated, 0);
    preferences.failRead = false;
    expect(await repository.load(), 'existing-installation');
    expect(generated, 0);
  });
  test(
    'gravação falha mantém candidato estável para a próxima tentativa',
    () async {
      final preferences = _Preferences()..failWrite = true;
      var generated = 0;
      final repository = TrainingInstallSeedRepository(
        preferences,
        createSeed: () => 'new-${++generated}',
      );
      await expectLater(repository.load(), throwsStateError);
      preferences.failWrite = false;
      expect(await repository.load(), 'new-1');
      expect(preferences.saved, 'new-1');
      expect(generated, 1);
    },
  );
}
