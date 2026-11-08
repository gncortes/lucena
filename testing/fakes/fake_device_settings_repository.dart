import 'package:lucena/data/repositories/device/device_settings_repository.dart';

/// Conta quantas vezes cada tela do sistema foi aberta.
class FakeDeviceSettingsRepository implements DeviceSettingsRepository {
  int notifications = 0;
  int appPermissions = 0;

  @override
  Future<bool> openNotifications() async {
    notifications++;
    return true;
  }

  @override
  Future<bool> openAppPermissions() async {
    appPermissions++;
    return true;
  }
}
