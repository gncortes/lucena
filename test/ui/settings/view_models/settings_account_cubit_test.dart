import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/settings/view_models/settings_account_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';

void main() {
  test('começa com a conta de agora', () async {
    final accounts = FakeAccountRepository(
      account: FakeAccountRepository.google,
    );
    final cubit = SettingsAccountCubit(accounts);
    addTearDown(cubit.close);

    expect(cubit.state?.uid, FakeAccountRepository.google.uid);
  });

  test('sem conta, começa nulo', () async {
    final cubit = SettingsAccountCubit(FakeAccountRepository());
    addTearDown(cubit.close);

    expect(cubit.state, isNull);
  });

  test('acompanha a entrada e a saída da conta', () async {
    final accounts = FakeAccountRepository();
    final cubit = SettingsAccountCubit(accounts);
    addTearDown(cubit.close);

    await accounts.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state?.uid, FakeAccountRepository.google.uid);

    await accounts.signOut();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isNull);
  });
}
