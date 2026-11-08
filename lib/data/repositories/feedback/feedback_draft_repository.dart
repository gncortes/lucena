import 'dart:convert';

import '../../../domain/models/feedback_entry.dart';
import '../../services/preferences_service.dart';

/// O rascunho do "Enviar feedback" (assunto e texto), para voltar depois de
/// fechar o app à força (H-OPI-11, gap 3). Apagado ao enviar.
abstract class FeedbackDraftRepository {
  Future<FeedbackDraft?> load();
  Future<void> save(FeedbackDraft draft);
  Future<void> clear();
}

/// Nas preferências do aparelho, em `feedback.v1.draft`. JSON estragado vale
/// como "sem rascunho".
class LocalFeedbackDraftRepository implements FeedbackDraftRepository {
  const LocalFeedbackDraftRepository(this._preferences);

  final PreferencesService _preferences;

  static const key = 'feedback.v1.draft';

  @override
  Future<FeedbackDraft?> load() async {
    final raw = await _preferences.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?> ? FeedbackDraft.fromJson(json) : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> save(FeedbackDraft draft) =>
      _preferences.setString(key, jsonEncode(draft.toJson()));

  @override
  Future<void> clear() => _preferences.remove(key);
}

/// Sem lugar para gravar: o formulário começa sempre vazio.
class NoFeedbackDraftRepository implements FeedbackDraftRepository {
  const NoFeedbackDraftRepository();

  @override
  Future<FeedbackDraft?> load() async => null;

  @override
  Future<void> save(FeedbackDraft draft) async {}

  @override
  Future<void> clear() async {}
}
