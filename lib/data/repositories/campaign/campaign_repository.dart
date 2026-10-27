import 'dart:convert';

import '../../../domain/models/campaign.dart';
import '../../services/preferences_service.dart';

/// A campanha do último link de post que abriu o app (T84): o funil do
/// Analytics atribui a ela a aula aberta e a concluída, mesmo dias depois.
abstract class CampaignRepository {
  /// A campanha gravada, ou nula.
  Future<Campaign?> active();

  /// Grava [campaign] como a campanha atual (o link mais novo vence).
  Future<void> remember(Campaign campaign);

  /// A aula da campanha foi concluída: o funil fecha.
  Future<void> clear();

  /// A pessoa aceitou o convite de conta antes da aula da campanha.
  Future<void> markInvited();

  /// Aceitou o convite e ainda não entrou: devolve `true` uma vez só (o
  /// `campanha_cadastro` `feito` sai na entrada que vem depois).
  Future<bool> takeInvited();
}

/// Grava a campanha no aparelho, em JSON.
class LocalCampaignRepository implements CampaignRepository {
  LocalCampaignRepository(this._preferences);

  final PreferencesService _preferences;

  static const _key = 'campaign.active';
  static const _invitedKey = 'campaign.invited';

  @override
  Future<Campaign?> active() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return null;
    try {
      return Campaign.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> remember(Campaign campaign) =>
      _preferences.setString(_key, jsonEncode(campaign.toJson()));

  @override
  Future<void> clear() async {
    await _preferences.remove(_key);
    await _preferences.remove(_invitedKey);
  }

  @override
  Future<void> markInvited() => _preferences.setBool(_invitedKey, value: true);

  @override
  Future<bool> takeInvited() async {
    final invited = await _preferences.getBool(_invitedKey) ?? false;
    if (invited) await _preferences.remove(_invitedKey);
    return invited;
  }
}

/// Sem gravar: a campanha vive enquanto o app está aberto (testes e o
/// padrão das dependências).
class MemoryCampaignRepository implements CampaignRepository {
  MemoryCampaignRepository([this.saved]);

  Campaign? saved;
  bool invited = false;

  @override
  Future<Campaign?> active() async => saved;

  @override
  Future<void> remember(Campaign campaign) async => saved = campaign;

  @override
  Future<void> clear() async {
    saved = null;
    invited = false;
  }

  @override
  Future<void> markInvited() async => invited = true;

  @override
  Future<bool> takeInvited() async {
    final was = invited;
    invited = false;
    return was;
  }
}
