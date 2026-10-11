import '../../services/preferences_service.dart';
import 'conclusion_repository.dart';

/// A conclusão aberta, nas preferências do aparelho.
class LocalConclusionRepository implements ConclusionRepository {
  const LocalConclusionRepository(this._preferences);

  final PreferencesService _preferences;

  static const _key = 'conclusion.pending';

  @override
  Future<int?> pending() async =>
      int.tryParse(await _preferences.getString(_key) ?? '');

  @override
  Future<void> open(int gameId) => _preferences.setString(_key, '$gameId');

  @override
  Future<void> clear() => _preferences.remove(_key);
}
