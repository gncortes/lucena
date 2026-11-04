import '../../services/preferences_service.dart';

/// O aviso geral de finais novos (o sino da lista de finais em destaque,
/// H-DES-06). É um só: não há aviso por torneio.
abstract class FeaturedAlertsRepository {
  /// O jogador quer o aviso de final novo? Desligado por padrão.
  Future<bool> enabled();

  Future<void> setEnabled({required bool value});
}

/// Gravado nas preferências do aparelho.
class LocalFeaturedAlertsRepository implements FeaturedAlertsRepository {
  LocalFeaturedAlertsRepository(this._preferences);

  final PreferencesService _preferences;

  static const _key = 'featured_notify';

  @override
  Future<bool> enabled() async => await _preferences.getBool(_key) ?? false;

  @override
  Future<void> setEnabled({required bool value}) =>
      _preferences.setBool(_key, value: value);
}
