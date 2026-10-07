import 'dart:convert';

import '../../../domain/models/home_layout.dart';
import '../../services/preferences_service.dart';

/// Os caminhos da tela inicial que o jogador escolheu, e se ele já viu o
/// aviso de que dá para escolher.
abstract class HomeLayoutRepository {
  /// O layout gravado. Nulo: nada gravado (a tela usa a sugestão do nível).
  Future<HomeLayout?> load();

  Future<void> save(HomeLayout layout);

  /// O aviso único "Agora dá para escolher o que aparece aqui" já saiu.
  Future<bool> noticeSeen();

  Future<void> markNoticeSeen();
}

/// Gravado nas preferências do aparelho.
class LocalHomeLayoutRepository implements HomeLayoutRepository {
  LocalHomeLayoutRepository(this._preferences);

  static const _layoutKey = 'home.layout';
  static const _noticeKey = 'home.layoutNotice';

  final PreferencesService _preferences;

  @override
  Future<HomeLayout?> load() async {
    final text = await _preferences.getString(_layoutKey);
    if (text == null) return null;
    try {
      return HomeLayout.fromJson(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(HomeLayout layout) =>
      _preferences.setString(_layoutKey, jsonEncode(layout.toJson()));

  @override
  Future<bool> noticeSeen() async =>
      await _preferences.getBool(_noticeKey) ?? false;

  @override
  Future<void> markNoticeSeen() =>
      _preferences.setBool(_noticeKey, value: true);
}
