import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/lichess/lichess_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
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

  group('S4 · Salvando, depois Salvo', () {
    test('com conta, passa por salvando e termina salvo', () async {
      accounts.account = FakeAccountRepository.google;
      final gate = sync.gate = Completer<void>();
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
      expect(cubit.state.syncPhase, ProfileSyncPhase.saving);

      gate.complete();
      await pumpEventQueue();
      expect(cubit.state.syncPhase, ProfileSyncPhase.saved);
    });

    test('sem rede termina offline, e só então', () async {
      accounts.account = FakeAccountRepository.google;
      sync.offline = true;
      final cubit = await build();
      expect(cubit.state.syncPhase, ProfileSyncPhase.offline);
    });

    test('envio que falha não diz salvo: vai a offline', () async {
      accounts.account = FakeAccountRepository.google;
      sync.pushFails = true;
      final cubit = await build();
      expect(cubit.state.syncPhase, ProfileSyncPhase.offline);
    });

    testWidgets('envio que não confirma em 10 s vai a offline e depois salvo', (
      tester,
    ) async {
      // O relógio do testWidgets é falso (fake_async): sem espera real.
      accounts.account = FakeAccountRepository.google;
      final gate = sync.gate = Completer<void>();
      final scheduler = SyncScheduler(accounts, sync);
      final cubit = ProfileAccountCubit(
        accounts: accounts,
        sync: scheduler,
        lichess: lichess,
        profile: profiles,
      );
      addTearDown(() {
        unawaited(cubit.close());
        unawaited(scheduler.dispose());
      });
      unawaited(cubit.load());
      await tester.pump();
      expect(cubit.state.syncPhase, ProfileSyncPhase.saving);

      await tester.pump(const Duration(seconds: 9));
      expect(cubit.state.syncPhase, ProfileSyncPhase.saving);
      await tester.pump(const Duration(seconds: 2));
      expect(cubit.state.syncPhase, ProfileSyncPhase.offline);

      gate.complete();
      await tester.pump();
      expect(cubit.state.syncPhase, ProfileSyncPhase.saved);
    });

    test('conta criada agora: salvando, salvo', () async {
      final gate = sync.gate = Completer<void>();
      final cubit = await build();
      expect(cubit.state.syncPhase, ProfileSyncPhase.idle);
      await accounts.signInWithGoogle();
      await pumpEventQueue();
      expect(cubit.state.syncPhase, ProfileSyncPhase.saving);
      gate.complete();
      await pumpEventQueue();
      expect(cubit.state.syncPhase, ProfileSyncPhase.saved);
    });
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

  group('H-CON-13 gap 5', () {
    test('sair falhando avisa e mantém a conta', () async {
      accounts.account = FakeAccountRepository.google;
      final cubit = await build();
      accounts.signOutError = Exception('falhou');
      await cubit.signOut();
      await pumpEventQueue();

      expect(cubit.state.account, FakeAccountRepository.google);
      expect(cubit.state.notice, ProfileNotice.failed);
      expect(cubit.state.busy, isFalse);
    });

    test('sair trava o segundo toque', () async {
      accounts.account = FakeAccountRepository.google;
      final cubit = await build();
      final first = cubit.signOut();
      expect(cubit.state.busy, isTrue);
      await cubit.signOut();
      await first;
      expect(accounts.signOuts, 1);
    });

    test('desconectar o Lichess falhando avisa e mantém o vínculo', () async {
      lichess.connected = true;
      final cubit = await build();
      lichess.disconnectError = Exception('falhou');
      await cubit.disconnectLichess();

      expect(cubit.state.lichess, rating);
      expect(profiles.profile.lichessUser, 'ana');
      expect(cubit.state.notice, ProfileNotice.failed);
      expect(cubit.state.busy, isFalse);
    });
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
