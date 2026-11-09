import 'dart:convert';

import '../../../domain/use_cases/treinador/treinador_regras.dart';
import '../../services/preferences_service.dart';

/// O que o Treinador guarda só no aparelho: o filtro da aba Partidas e
/// quando cada análise começou (para a porcentagem da espera continuar de
/// onde estava depois de fechar o app).
class TreinadorPreferencias {
  TreinadorPreferencias([PreferencesService? preferences])
    : _preferences = preferences ?? PreferencesService();

  static const filtroKey = 'treinador.filtro';
  static String inicioKey(String id) => 'treinador.analise.inicio.$id';

  final PreferencesService _preferences;

  Future<FiltroPartidas> filtro() async {
    final raw = await _preferences.getString(filtroKey);
    if (raw == null) return FiltroPartidas.todos;
    try {
      return FiltroPartidas.fromJson(jsonDecode(raw));
    } on FormatException {
      return FiltroPartidas.todos;
    }
  }

  Future<void> salvarFiltro(FiltroPartidas filtro) => filtro.vazio
      ? _preferences.remove(filtroKey)
      : _preferences.setString(filtroKey, jsonEncode(filtro.toJson()));

  Future<DateTime?> inicioDaAnalise(String id) async {
    final raw = await _preferences.getString(inicioKey(id));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> marcarInicio(String id, DateTime quando) =>
      _preferences.setString(inicioKey(id), quando.toUtc().toIso8601String());

  Future<void> esquecerInicio(String id) => _preferences.remove(inicioKey(id));
}
