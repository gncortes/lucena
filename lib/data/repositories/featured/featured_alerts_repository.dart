import 'dart:convert';

import '../../services/preferences_service.dart';

/// O aviso geral de finais novos (o sino da lista de finais em destaque,
/// H-DES-06). É um só: não há aviso por torneio.
abstract class FeaturedAlertsRepository {
  /// O jogador quer o aviso de final novo? Desligado por padrão.
  Future<bool> enabled();

  Future<void> setEnabled({required bool value});

  /// O jogador já respondeu ao cartão "Quer saber quando sair outro final
  /// assim?" no fim do final [id] (H-INI-07)? Depois de responder, o cartão
  /// não volta nesse final.
  Future<bool> promptAnswered(String id);

  Future<void> markPromptAnswered(String id);
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

  static const _promptedKey = 'featured_notify_prompted';

  Future<Set<String>> _prompted() async {
    final text = await _preferences.getString(_promptedKey);
    if (text == null) return {};
    try {
      return {for (final id in jsonDecode(text) as List) id as String};
    } on Object {
      return {};
    }
  }

  @override
  Future<bool> promptAnswered(String id) async =>
      (await _prompted()).contains(id);

  @override
  Future<void> markPromptAnswered(String id) async {
    final all = await _prompted();
    if (!all.add(id)) return;
    await _preferences.setString(
      _promptedKey,
      jsonEncode(all.toList()..sort()),
    );
  }
}
