import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_invite_cubit.dart';

import '../../../../testing/fakes/fake_account_invite_repository.dart';
import '../../../../testing/fakes/fake_account_repository.dart';

void main() {
  test('sem conta e com o convite livre, mostra o cartão', () async {
    final cubit = ConclusionInviteCubit(
      accounts: FakeAccountRepository(),
      invite: FakeAccountInviteRepository(),
    );
    addTearDown(cubit.close);

    await cubit.check();

    expect(cubit.state, isTrue);
  });

  test('com conta, não convida', () async {
    final cubit = ConclusionInviteCubit(
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      invite: FakeAccountInviteRepository(),
    );
    addTearDown(cubit.close);

    await cubit.check();

    expect(cubit.state, isFalse);
  });

  test('convite suspenso não aparece', () async {
    final cubit = ConclusionInviteCubit(
      accounts: FakeAccountRepository(),
      invite: FakeAccountInviteRepository(shown: true),
    );
    addTearDown(cubit.close);

    await cubit.check();

    expect(cubit.state, isFalse);
  });

  test('sem o repositório do convite, nunca convida', () async {
    final cubit = ConclusionInviteCubit();
    addTearDown(cubit.close);

    await cubit.check();

    expect(cubit.state, isFalse);
  });

  test('fechar o cartão some e suspende o convite', () async {
    final invite = FakeAccountInviteRepository();
    final cubit = ConclusionInviteCubit(
      accounts: FakeAccountRepository(),
      invite: invite,
    );
    addTearDown(cubit.close);
    await cubit.check();

    await cubit.dismiss();

    expect(cubit.state, isFalse);
    expect(invite.shown, isTrue);
  });

  test('fechar sem o cartão à vista não suspende', () async {
    final invite = FakeAccountInviteRepository();
    final cubit = ConclusionInviteCubit(
      accounts: FakeAccountRepository(),
      invite: invite,
    );
    addTearDown(cubit.close);

    await cubit.dismiss();

    expect(invite.shown, isFalse);
  });
}
