import '../../services/preferences_service.dart';

/// Os modos novos que o jogador já viu anunciados na tela inicial (o
/// cartão "Novo modo desbloqueado" aparece uma vez só).
abstract class UnlockRepository {
  Future<bool> seen(String mode);

  Future<void> markSeen(String mode);
}

/// Gravado nas preferências do aparelho.
class LocalUnlockRepository implements UnlockRepository {
  LocalUnlockRepository(this._preferences);

  final PreferencesService _preferences;

  static String _key(String mode) => 'unlock.$mode.seen';

  @override
  Future<bool> seen(String mode) async =>
      await _preferences.getBool(_key(mode)) ?? false;

  @override
  Future<void> markSeen(String mode) =>
      _preferences.setBool(_key(mode), value: true);
}
