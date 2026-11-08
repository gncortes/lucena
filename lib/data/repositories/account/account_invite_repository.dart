import '../../../domain/use_cases/now.dart';
import '../../services/preferences_service.dart';

/// O convite para criar conta (H-CON-02/03): "Agora não" ou o X o suspendem
/// por [snooze]; depois ele volta.
abstract class AccountInviteRepository {
  /// Quanto tempo o convite fica suspenso depois de mostrado.
  static const snooze = Duration(days: 7);

  /// Se o convite pode aparecer agora.
  Future<bool> pending();

  /// O convite saiu (e foi recusado ou fechado): suspende por [snooze].
  Future<void> markShown();
}

/// Gravado nas preferências do aparelho: sobrevive a fechar à força.
class LocalAccountInviteRepository implements AccountInviteRepository {
  const LocalAccountInviteRepository(
    this._preferences, {
    this._now = const SystemNow(),
  });

  static const _snoozeKey = 'account.invite.snoozeUntil';

  final PreferencesService _preferences;
  final Now _now;

  @override
  Future<bool> pending() async {
    final until = DateTime.tryParse(
      await _preferences.getString(_snoozeKey) ?? '',
    );
    return until == null || !_now().isBefore(until);
  }

  @override
  Future<void> markShown() => _preferences.setString(
    _snoozeKey,
    _now().add(AccountInviteRepository.snooze).toIso8601String(),
  );
}

/// Nunca convida: os testes e o modo E2E, que não esperam a folha.
class NoAccountInviteRepository implements AccountInviteRepository {
  const NoAccountInviteRepository();

  @override
  Future<bool> pending() async => false;

  @override
  Future<void> markShown() async {}
}
