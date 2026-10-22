import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/platform_rating.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/profile_account_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_lichess_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';

void main() {
  late FakeAccountRepository accounts;
  late FakeSyncRepository sync;
  late FakeLichessRepository lichess;
  late FakeProfileRepository profiles;

  const email = Account(
    uid: 'email-uid',
    provider: AccountProvider.email,
    email: 'ana@example.com',
  );
  final rating = PlatformRating(user: 'ana', readAt: DateTime(2026, 10, 20));

  setUp(() {
    accounts = FakeAccountRepository();
    sync = FakeSyncRepository();
    lichess = FakeLichessRepository(rating: rating);
    profiles = FakeProfileRepository(const UserProfile(lichessUser: 'ana'));
  });

  Future<ProfileAccountCubit> build() async {
    final scheduler = SyncScheduler(accounts, sync);
    addTearDown(scheduler.dispose);
    final cubit = ProfileAccountCubit(
      accounts: accounts,
      sync: scheduler,
      lichess: lichess,
      profile: profiles,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await pumpEventQueue();
    return cubit;
  }

  test('com conta, lê a última sincronização e sobe o pendente', () async {
    accounts.account = FakeAccountRepository.google;
    sync.at = DateTime(2026, 10, 22, 9);
    final cubit = await build();

    expect(cubit.state.account, FakeAccountRepository.google);
    expect(cubit.state.syncedAt, DateTime(2026, 10, 22, 9));
    expect(sync.synced, ['google-uid']);
  });

  test('sem conta, nada sobe', () async {
    final cubit = await build();
    expect(cubit.state.account, isNull);
    expect(sync.synced, isEmpty);
  });

  test('sair tira a conta e a última sincronização', () async {
    accounts.account = FakeAccountRepository.google;
    sync.at = DateTime(2026, 10, 22, 9);
    final cubit = await build();
    await cubit.signOut();
    await pumpEventQueue();

    expect(cubit.state.account, isNull);
    expect(cubit.state.syncedAt, isNull);
  });

  test('apagar a conta avisa que foi apagada', () async {
    accounts.account = FakeAccountRepository.google;
    final cubit = await build();
    await cubit.deleteAccount();
    await pumpEventQueue();

    expect(accounts.current, isNull);
    expect(cubit.state.notice, ProfileNotice.deleted);
    expect(cubit.state.busy, isFalse);
  });

  test('apagar sem rede não apaga', () async {
    accounts.account = FakeAccountRepository.google;
    final cubit = await build();
    accounts.failure = AccountFailure.network;
    await cubit.deleteAccount();

    expect(accounts.current, FakeAccountRepository.google);
    expect(cubit.state.notice, ProfileNotice.deleteOffline);
  });

  test('com e-mail, o login recente pedido vira aviso para a tela', () async {
    accounts.account = email;
    final cubit = await build();
    accounts.failure = AccountFailure.recentLoginRequired;
    await cubit.deleteAccount();

    expect(accounts.current, email);
    expect(cubit.state.notice, ProfileNotice.deleteRelogin);
  });

  test('depois de entrar de novo, só apaga a mesma conta', () async {
    accounts.account = email;
    final cubit = await build();
    accounts.account = FakeAccountRepository.google;
    await cubit.deleteAfterSignIn(email.uid);

    expect(accounts.current, FakeAccountRepository.google);
    expect(cubit.state.notice, ProfileNotice.deleteFailed);

    accounts.account = email;
    await cubit.deleteAfterSignIn(email.uid);
    expect(accounts.current, isNull);
    expect(cubit.state.notice, ProfileNotice.deleted);
  });

  test('o mesmo aviso de novo conta outra vez', () async {
    accounts.account = FakeAccountRepository.google;
    final cubit = await build();
    accounts.failure = AccountFailure.network;
    await cubit.deleteAccount();
    final first = cubit.state.noticeCount;
    await cubit.deleteAccount();

    expect(cubit.state.noticeCount, first + 1);
  });

  group('Lichess', () {
    setUp(() => lichess.connected = true);

    test('carrega a última leitura', () async {
      final cubit = await build();
      expect(cubit.state.lichess, rating);
    });

    test('atualizar sem rede fica com a leitura de antes', () async {
      final cubit = await build();
      lichess.failure = LichessFailure.network;
      await cubit.refreshLichess();

      expect(cubit.state.lichess, rating);
      expect(cubit.state.notice, ProfileNotice.lichessOffline);
      expect(cubit.state.busy, isFalse);
    });

    test('desconectar tira o acesso e o vínculo do perfil', () async {
      final cubit = await build();
      await cubit.disconnectLichess();

      expect(cubit.state.lichess, isNull);
      expect(lichess.connected, isFalse);
      expect(profiles.profile.lichessUser, isNull);
    });
  });
}
