import '../../services/preferences_service.dart';

/// A folha "Quer ver torneios perto de você?" (E1.21): aparece uma vez só, na
/// primeira abertura da lista de finais de torneios.
abstract class RegionPromptRepository {
  /// A folha ainda não apareceu.
  Future<bool> pending();

  /// A folha apareceu (salvou ou "Agora não"): não pergunta de novo.
  Future<void> done();
}

class LocalRegionPromptRepository implements RegionPromptRepository {
  LocalRegionPromptRepository(this._preferences);

  static const _key = 'alerts.regionAsked';

  final PreferencesService _preferences;

  @override
  Future<bool> pending() async => !(await _preferences.getBool(_key) ?? false);

  @override
  Future<void> done() => _preferences.setBool(_key, value: true);
}

/// Nunca pergunta (testes que não são da folha).
class NoRegionPromptRepository implements RegionPromptRepository {
  const NoRegionPromptRepository();

  @override
  Future<bool> pending() async => false;

  @override
  Future<void> done() async {}
}
