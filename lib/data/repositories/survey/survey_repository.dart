import 'dart:convert';

import '../../../domain/models/survey.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/preferences_service.dart';

/// O questionário "Sua opinião": o rascunho e a resposta, no aparelho. O envio
/// ao servidor é da E1.03.
abstract class SurveyRepository {
  /// O rascunho de [kind]; nulo se não há.
  Future<SurveyDraft?> loadDraft(SurveyKind kind);

  Future<void> saveDraft(SurveyDraft draft);

  /// A resposta enviada de [kind]; nula se ainda não respondeu.
  Future<SurveyResponse?> loadResponse(SurveyKind kind);

  /// Grava a resposta (com a hora do [Now]) e apaga o rascunho do mesmo
  /// [kind]. Devolve o que foi gravado.
  Future<SurveyResponse> saveResponse(SurveyKind kind, SurveyAnswers answers);
}

/// Gravado nas preferências do aparelho, em JSON. JSON estragado vale como
/// "não existe".
class LocalSurveyRepository implements SurveyRepository {
  LocalSurveyRepository(this._preferences, this._now);

  final PreferencesService _preferences;
  final Now _now;

  static String draftKey(SurveyKind kind) => 'survey.v1.${kind.code}.draft';

  static String responseKey(SurveyKind kind) =>
      'survey.v1.${kind.code}.response';

  Future<T?> _read<T>(
    String key,
    T Function(Map<String, Object?> json) parse,
  ) async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?> ? parse(json) : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<SurveyDraft?> loadDraft(SurveyKind kind) async {
    final draft = await _read(draftKey(kind), SurveyDraft.fromJson);
    return draft?.kind == kind ? draft : null;
  }

  @override
  Future<void> saveDraft(SurveyDraft draft) =>
      _preferences.setString(draftKey(draft.kind), jsonEncode(draft.toJson()));

  @override
  Future<SurveyResponse?> loadResponse(SurveyKind kind) async {
    final response = await _read(responseKey(kind), SurveyResponse.fromJson);
    return response?.kind == kind ? response : null;
  }

  @override
  Future<SurveyResponse> saveResponse(
    SurveyKind kind,
    SurveyAnswers answers,
  ) async {
    final response = SurveyResponse(
      kind: kind,
      answers: answers.cleaned,
      answeredAt: _now(),
    );
    // A resposta primeiro: se o app fechar no meio, o convite já sumiu.
    await _preferences.setString(
      responseKey(kind),
      jsonEncode(response.toJson()),
    );
    await _preferences.remove(draftKey(kind));
    return response;
  }
}
