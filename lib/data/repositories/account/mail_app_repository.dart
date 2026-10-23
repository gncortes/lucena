import '../../services/system_settings_service.dart';

/// O app de e-mail do aparelho: "Abrir o e-mail" depois de pedir o link de
/// senha nova (§2.12).
abstract class MailAppRepository {
  /// Falso: não há app de e-mail e o botão some.
  Future<bool> available();

  Future<void> open();
}

class DeviceMailAppRepository implements MailAppRepository {
  const DeviceMailAppRepository([this._system = const SystemSettingsService()]);

  final SystemSettingsService _system;

  @override
  Future<bool> available() => _system.hasEmailApp();

  @override
  Future<void> open() => _system.openEmailApp();
}

/// Sem app de e-mail (testes, outras plataformas).
class NoMailAppRepository implements MailAppRepository {
  const NoMailAppRepository();

  @override
  Future<bool> available() async => false;

  @override
  Future<void> open() async {}
}
