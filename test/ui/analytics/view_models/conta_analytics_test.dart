import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/progress_summary.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/account/view_models/account_cubit.dart';
import 'package:lucena/ui/profile/view_models/profile_account_cubit.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_lichess_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';

void main() {
  late FakeAccountRepository accounts;
  late FakeSyncRepository sync;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    accounts = FakeAccountRepository();
    sync = FakeSyncRepository();
    analytics = FakeAnalyticsRepository();
  });

  AccountCubit accountCubit() {
    final scheduler = SyncScheduler(accounts, sync);
    addTearDown(scheduler.dispose);
    final cubit = AccountCubit(accounts, sync: scheduler, analytics: analytics);
    addTearDown(cubit.close);
    return cubit;
  }

  group('AccountCubit', () {
    test('Google é login com method=google', () async {
      await accountCubit().signInWithGoogle();
      final events = analytics.eventsNamed('login');
      expect(events, hasLength(1));
      expect(events.single.params, {'method': 'google'});
      expect(analytics.eventsNamed('sign_up'), isEmpty);
    });

    test('e-mail: entrar é login; criar é sign_up', () async {
      await accountCubit().signInWithEmail('a@b.com', 'senha1234');
      expect(analytics.eventsNamed('login').single.params, {'method': 'email'});

      await accountCubit().createWithEmail('c@d.com', 'senha1234');
      expect(analytics.eventsNamed('sign_up').single.params, {
        'method': 'email',
      });
    });

    test('senha fraca ou falha não contam entrada', () async {
      await accountCubit().createWithEmail('c@d.com', '123');
      accounts.failure = AccountFailure.wrongCredentials;
      await accountCubit().signInWithEmail('a@b.com', 'x');
      expect(analytics.events, isEmpty);
    });

    test(
      'conta com progresso: conta_progresso_recuperado com os itens',
      () async {
        sync.remote = const ProgressSummary(
          school: {'a', 'b'},
          stars: {'x': 2},
        );
        await accountCubit().signInWithGoogle();
        expect(
          analytics.eventsNamed('conta_progresso_recuperado').single.params,
          {'itens': 3},
        );
      },
    );

    test('conta vazia ou criada agora não recupera nada', () async {
      await accountCubit().signInWithGoogle();
      sync.remote = const ProgressSummary(school: {'a'});
      await accountCubit().createWithEmail('c@d.com', 'senha1234');
      expect(analytics.eventsNamed('conta_progresso_recuperado'), isEmpty);
    });
  });

  group('ProfileAccountCubit', () {
    Future<ProfileAccountCubit> profileCubit() async {
      final scheduler = SyncScheduler(accounts, sync);
      addTearDown(scheduler.dispose);
      final cubit = ProfileAccountCubit(
        accounts: accounts,
        sync: scheduler,
        lichess: FakeLichessRepository(),
        profile: FakeProfileRepository(const UserProfile()),
        analytics: analytics,
      );
      addTearDown(cubit.close);
      await cubit.load();
      await pumpEventQueue();
      return cubit;
    }

    test('apagar a conta loga conta_apagada uma vez', () async {
      accounts.account = FakeAccountRepository.google;
      final cubit = await profileCubit();
      await cubit.deleteAccount();
      expect(analytics.eventsNamed('conta_apagada'), hasLength(1));
    });

    test('apagar que falhou não loga', () async {
      accounts.account = FakeAccountRepository.google;
      final cubit = await profileCubit();
      accounts.failure = AccountFailure.network;
      await cubit.deleteAccount();
      expect(analytics.eventsNamed('conta_apagada'), isEmpty);
    });
  });
}
