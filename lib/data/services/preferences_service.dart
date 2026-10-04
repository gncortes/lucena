import 'package:shared_preferences/shared_preferences.dart';

/// Embrulha o `shared_preferences`: chave e valor simples, gravados no aparelho.
class PreferencesService {
  PreferencesService([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  Future<String?> getString(String key) => _preferences.getString(key);

  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  Future<bool?> getBool(String key) => _preferences.getBool(key);

  Future<void> setBool(String key, {required bool value}) =>
      _preferences.setBool(key, value);

  Future<void> remove(String key) => _preferences.remove(key);

  Future<void> clear() => _preferences.clear();
}
