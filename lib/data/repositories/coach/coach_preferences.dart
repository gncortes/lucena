import 'dart:convert';

import '../../../domain/use_cases/coach/coach_rules.dart';
import '../../services/preferences_service.dart';

/// O que o Treinador guarda só no aparelho: o filtro da aba Partidas e
/// quando cada análise começou (para a porcentagem da espera continuar de
/// onde estava depois de fechar o app) e as tentativas e dicas do exercício
/// aberto (fechar à força no meio não devolve os pontos).
class CoachPreferences {
  CoachPreferences([PreferencesService? preferences])
    : _preferences = preferences ?? PreferencesService();

  static const filterKey = 'treinador.filtro';
  static String startKey(String id) => 'treinador.analise.inicio.$id';

  static String attemptsKey(String id) => 'treinador.exercicio.tentativas.$id';

  final PreferencesService _preferences;

  Future<GameFilter> filter() async {
    final raw = await _preferences.getString(filterKey);
    if (raw == null) return GameFilter.everyone;
    try {
      return GameFilter.fromJson(jsonDecode(raw));
    } on FormatException {
      return GameFilter.everyone;
    }
  }

  Future<void> saveFilter(GameFilter filter) => filter.empty
      ? _preferences.remove(filterKey)
      : _preferences.setString(filterKey, jsonEncode(filter.toJson()));

  Future<DateTime?> startOfAnalysis(String id) async {
    final raw = await _preferences.getString(startKey(id));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markStart(String id, DateTime when_) =>
      _preferences.setString(startKey(id), when_.toUtc().toIso8601String());

  Future<void> forgetStart(String id) => _preferences.remove(startKey(id));

  /// Quantas tentativas o exercício [n] da partida [id] já está na (1 se não
  /// houve erro guardado, ou se o guardado é de outro exercício).
  Future<int> attempts(String id, int n) async =>
      (await _stored(id, n))?.attempts ?? 1;

  /// Quantas dicas o exercício [n] da partida [id] já usou (0 se nenhuma, ou
  /// se o guardado é de outro exercício).
  Future<int> hints(String id, int n) async =>
      (await _stored(id, n))?.hints ?? 0;

  /// "n:tentativas" ou, com dica, "n:tentativas:dicas".
  Future<({int attempts, int hints})?> _stored(String id, int n) async {
    final parts = (await _preferences.getString(attemptsKey(id)))?.split(':');
    if (parts == null || parts.length < 2 || parts.length > 3) return null;
    final stored = int.tryParse(parts[0]);
    final attempts = int.tryParse(parts[1]);
    final hints = parts.length == 3 ? int.tryParse(parts[2]) : 0;
    if (stored != n || attempts == null || attempts < 1) return null;
    return (attempts: attempts, hints: hints == null || hints < 0 ? 0 : hints);
  }

  Future<void> saveAttempts(String id, int n, int attempts, {int hints = 0}) =>
      _preferences.setString(
        attemptsKey(id),
        hints > 0 ? '$n:$attempts:$hints' : '$n:$attempts',
      );

  Future<void> forgetAttempts(String id) =>
      _preferences.remove(attemptsKey(id));
}
