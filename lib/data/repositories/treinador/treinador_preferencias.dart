import 'dart:convert';

import '../../../domain/use_cases/treinador/treinador_regras.dart';
import '../../services/preferences_service.dart';

/// O que o Treinador guarda só no aparelho: o filtro da aba Partidas e
/// quando cada análise começou (para a porcentagem da espera continuar de
/// onde estava depois de fechar o app) e as tentativas do exercício aberto
/// (fechar à força no meio não devolve os pontos).
class TreinadorPreferencias {
  TreinadorPreferencias([PreferencesService? preferences])
    : _preferences = preferences ?? PreferencesService();

  static const filtroKey = 'treinador.filtro';
  static String inicioKey(String id) => 'treinador.analise.inicio.$id';

  static String tentativasKey(String id) =>
      'treinador.exercicio.tentativas.$id';

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

  /// Quantas tentativas o exercício [n] da partida [id] já está na (1 se não
  /// houve erro guardado, ou se o guardado é de outro exercício).
  Future<int> tentativas(String id, int n) async {
    final partes = (await _preferences.getString(tentativasKey(id)))
        ?.split(':');
    if (partes == null || partes.length != 2) return 1;
    final guardado = int.tryParse(partes[0]);
    final tentativas = int.tryParse(partes[1]);
    if (guardado != n || tentativas == null || tentativas < 1) return 1;
    return tentativas;
  }

  Future<void> salvarTentativas(String id, int n, int tentativas) =>
      _preferences.setString(tentativasKey(id), '$n:$tentativas');

  Future<void> esquecerTentativas(String id) =>
      _preferences.remove(tentativasKey(id));
}
