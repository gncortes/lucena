import 'dart:math';

import '../../services/preferences_service.dart';

/// A failed read never means a new installation. A failed write retains its
/// candidate in memory, and every retry checks the persisted value first.
class TrainingInstallSeedRepository {
  TrainingInstallSeedRepository(
    this._preferences, {
    String Function()? createSeed,
  }) : _createSeed = createSeed ?? _randomSeed;

  final PreferencesService _preferences;
  final String Function() _createSeed;
  Future<String>? _loading;
  String? _candidate;

  Future<String> load() =>
      _loading ??= _read().catchError((Object error, StackTrace stack) {
        _loading = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<String> _read() async {
    const key = 'training.installSeed';
    final saved = await _preferences.getString(key);
    if (saved != null && saved.isNotEmpty) return saved;
    final candidate = _candidate ??= _createSeed();
    await _preferences.setString(key, candidate);
    return candidate;
  }

  static String _randomSeed() {
    final random = Random.secure();
    return List.generate(
      32,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
