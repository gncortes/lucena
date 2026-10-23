import '../../services/preferences_service.dart';

/// O convite para criar conta no fim da 1ª partida (E1.13): uma vez por
/// instalação. Depois dele, a conta fica só no Perfil.
abstract class AccountInviteRepository {
  /// Se o convite ainda não foi mostrado neste aparelho.
  Future<bool> pending();

  Future<void> markShown();
}

/// Gravado nas preferências do aparelho.
class LocalAccountInviteRepository implements AccountInviteRepository {
  const LocalAccountInviteRepository(this._preferences);

  static const _shownKey = 'account.invited';

  final PreferencesService _preferences;

  @override
  Future<bool> pending() async =>
      !(await _preferences.getBool(_shownKey) ?? false);

  @override
  Future<void> markShown() => _preferences.setBool(_shownKey, value: true);
}

/// Nunca convida: os testes e o modo E2E, que não esperam a folha.
class NoAccountInviteRepository implements AccountInviteRepository {
  const NoAccountInviteRepository();

  @override
  Future<bool> pending() async => false;

  @override
  Future<void> markShown() async {}
}
