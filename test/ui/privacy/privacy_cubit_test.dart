import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/privacy/view_models/privacy_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_device_settings_repository.dart';

void main() {
  late FakeDeviceSettingsRepository device;

  setUp(() => device = FakeDeviceSettingsRepository());

  PrivacyCubit cubit(FakeAccountRepository accounts) =>
      PrivacyCubit(accounts: accounts, device: device);

  test('sem conta: pronta e sem as linhas da conta', () async {
    final privacy = cubit(FakeAccountRepository());
    await privacy.load();
    expect(privacy.state.ready, isTrue);
    expect(privacy.state.hasAccount, isFalse);
    await privacy.close();
  });

  test('a conta entra e sai com a tela aberta', () async {
    final accounts = FakeAccountRepository();
    final privacy = cubit(accounts);
    await privacy.load();
    await pumpEventQueue();
    await accounts.signInWithGoogle();
    await pumpEventQueue();
    expect(privacy.state.hasAccount, isTrue);
    await accounts.signOut();
    await pumpEventQueue();
    expect(privacy.state.hasAccount, isFalse);
    await privacy.close();
  });

  test('Notificações e Microfone abrem os ajustes do sistema', () async {
    final privacy = cubit(FakeAccountRepository());
    await privacy.openNotifications();
    await privacy.openMicrophone();
    expect(device.notifications, 1);
    expect(device.appPermissions, 1);
    await privacy.close();
  });
}
