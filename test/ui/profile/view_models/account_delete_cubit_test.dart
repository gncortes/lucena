import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/avatar_photo.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/account_delete_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';

void main() {
  late FakeAccountRepository accounts;
  late FakeProfileRepository profiles;
  late FakeAnalyticsRepository analytics;

  const email = Account(
    uid: 'email-uid',
    provider: AccountProvider.email,
    email: 'ana@example.com',
  );

  setUp(() {
    accounts = FakeAccountRepository();
    profiles = FakeProfileRepository(const UserProfile());
    analytics = FakeAnalyticsRepository();
  });

  AccountDeleteCubit build(Account account) {
    accounts.account = account;
    final cubit = AccountDeleteCubit(
      uid: account.uid,
      accounts: accounts,
      profile: profiles,
      analytics: analytics,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('H-CON-14 · Excluir a conta', () {
    test('começa na pergunta, sem aviso', () {
      final cubit = build(FakeAccountRepository.google);
      expect(cubit.state.step, AccountDeleteStep.ask);
      expect(cubit.state.notice, isNull);
    });

    test('excluir passa por carregando e termina excluída', () async {
      final cubit = build(FakeAccountRepository.google);
      final steps = <AccountDeleteStep>[];
      final sub = cubit.stream.listen((s) => steps.add(s.step));
      await cubit.confirm();
      await pumpEventQueue();
      await sub.cancel();

      expect(steps, [AccountDeleteStep.deleting, AccountDeleteStep.deleted]);
      expect(accounts.current, isNull);
      expect(analytics.names, ['conta_apagada']);
    });

    test('carregando ignora o segundo toque', () async {
      final cubit = build(FakeAccountRepository.google);
      final gate = profiles.loadGate = Completer<void>();
      final first = cubit.confirm();
      await cubit.confirm();
      gate.complete();
      await first;
      expect(accounts.deletedUids, ['google-uid']);
    });

    test(
      'leva junto a foto enviada; sem ela, o Storage fica de fora',
      () async {
        await build(FakeAccountRepository.google).confirm();
        expect(accounts.deletedWithPhoto, isFalse);

        await profiles.save(const UserProfile(photo: AvatarPhoto.upload));
        await build(FakeAccountRepository.google).confirm();
        expect(accounts.deletedWithPhoto, isTrue);
      },
    );

    test('sem internet: nada é excluído e o aviso diz isso', () async {
      final cubit = build(FakeAccountRepository.google);
      accounts.failure = AccountFailure.network;
      await cubit.confirm();

      expect(accounts.current, FakeAccountRepository.google);
      expect(cubit.state.step, AccountDeleteStep.ask);
      expect(cubit.state.notice, AccountDeleteNotice.offline);
    });

    test('erro inesperado libera os botões e mostra Tentar de novo', () async {
      final cubit = build(FakeAccountRepository.google);
      accounts.failure = AccountFailure.unknown;
      await cubit.confirm();
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.notice, AccountDeleteNotice.failed);

      accounts.failure = null;
      await cubit.confirm();
      expect(cubit.state.step, AccountDeleteStep.deleted);
    });

    test('Google: desistir do novo login volta à folha com aviso', () async {
      final cubit = build(FakeAccountRepository.google);
      accounts.canceled = true;
      await cubit.confirm();

      expect(accounts.current, FakeAccountRepository.google);
      expect(cubit.state.step, AccountDeleteStep.ask);
      expect(cubit.state.notice, AccountDeleteNotice.cancelled);
    });

    test('e-mail: o login recente pedido vira o passo de senha', () async {
      final cubit = build(email);
      accounts.failure = AccountFailure.recentLoginRequired;
      await cubit.confirm();

      expect(accounts.current, email);
      expect(cubit.state.step, AccountDeleteStep.relogin);
    });

    test('e-mail: desistir da senha volta à folha com aviso', () async {
      final cubit = build(email);
      await cubit.afterSignIn(signedIn: false);
      expect(accounts.deletedUids, isEmpty);
      expect(cubit.state.notice, AccountDeleteNotice.cancelled);
    });

    test('depois de entrar de novo, só apaga a mesma conta', () async {
      var cubit = build(email);
      accounts.account = FakeAccountRepository.google;
      await cubit.afterSignIn(signedIn: true);
      expect(accounts.deletedUids, isEmpty);
      expect(accounts.current, isNull);
      expect(cubit.state.step, AccountDeleteStep.differentAccount);

      cubit = build(email);
      await cubit.afterSignIn(signedIn: true);
      expect(accounts.deletedUids, ['email-uid']);
      expect(cubit.state.step, AccountDeleteStep.deleted);
    });

    test('outra conta no novo login Google: nada apagado', () async {
      final cubit = build(FakeAccountRepository.google);
      accounts.failure = AccountFailure.userMismatch;
      await cubit.confirm();
      expect(accounts.deletedUids, isEmpty);
      expect(cubit.state.step, AccountDeleteStep.differentAccount);
    });
  });
}
