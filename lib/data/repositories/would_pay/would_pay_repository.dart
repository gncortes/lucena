import 'dart:convert';

import '../../../domain/models/would_pay.dart';
import '../../services/preferences_service.dart';

/// O rascunho do "Você pagaria?" e se o cartão ainda aparece (E1.26), no
/// aparelho. O envio é do `FeedbackRepository`.
abstract class WouldPayRepository {
  /// Nulo: não há rascunho.
  Future<WouldPayDraft?> loadDraft();

  Future<void> saveDraft(WouldPayDraft draft);

  /// "Agora não" ou já respondido: o cartão não volta.
  Future<bool> dismissed();
  Future<bool> answered();

  /// "Agora não": esconde o cartão para sempre.
  Future<void> dismiss();

  /// Enviado: marca respondido e apaga o rascunho.
  Future<void> markAnswered();
}

/// Nas preferências do aparelho. Rascunho estragado vale como "não existe".
class LocalWouldPayRepository implements WouldPayRepository {
  const LocalWouldPayRepository(this._preferences);

  final PreferencesService _preferences;

  static const draftKey = 'wouldPay.v1.draft';
  static const dismissedKey = 'wouldPay.v1.dismissed';
  static const answeredKey = 'wouldPay.v1.answered';

  @override
  Future<WouldPayDraft?> loadDraft() async {
    final raw = await _preferences.getString(draftKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?> ? WouldPayDraft.fromJson(json) : null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> saveDraft(WouldPayDraft draft) =>
      _preferences.setString(draftKey, jsonEncode(draft.toJson()));

  @override
  Future<bool> dismissed() async =>
      await _preferences.getBool(dismissedKey) ?? false;

  @override
  Future<bool> answered() async =>
      await _preferences.getBool(answeredKey) ?? false;

  @override
  Future<void> dismiss() => _preferences.setBool(dismissedKey, value: true);

  @override
  Future<void> markAnswered() async {
    // Respondido primeiro: se o app fechar no meio, o cartão já sumiu.
    await _preferences.setBool(answeredKey, value: true);
    await _preferences.remove(draftKey);
  }
}

/// Sem pesquisa (testes que não a usam): o cartão nunca aparece.
class NoWouldPayRepository implements WouldPayRepository {
  const NoWouldPayRepository();

  @override
  Future<WouldPayDraft?> loadDraft() async => null;

  @override
  Future<void> saveDraft(WouldPayDraft draft) async {}

  @override
  Future<bool> dismissed() async => true;

  @override
  Future<bool> answered() async => false;

  @override
  Future<void> dismiss() async {}

  @override
  Future<void> markAnswered() async {}
}
