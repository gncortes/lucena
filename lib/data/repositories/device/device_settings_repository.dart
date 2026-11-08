import '../../services/system_settings_service.dart';

/// As telas de permissão do sistema que a Privacidade e dados abre
/// (H-CON-20, "Permissões do aparelho").
abstract class DeviceSettingsRepository {
  /// Os ajustes de notificação do Lucena. Falso se não deu para abrir.
  Future<bool> openNotifications();

  /// Os ajustes do app no sistema, onde fica a permissão do microfone.
  Future<bool> openAppPermissions();
}

class SystemDeviceSettingsRepository implements DeviceSettingsRepository {
  const SystemDeviceSettingsRepository([
    this._system = const SystemSettingsService(),
  ]);

  final SystemSettingsService _system;

  @override
  Future<bool> openNotifications() => _system.openAppNotifications();

  @override
  Future<bool> openAppPermissions() => _system.openAppDetails();
}
