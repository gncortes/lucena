import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/sync/sync_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';

import '../../../../testing/fakes/fake_account_repository.dart';
import '../../../../testing/fakes/fake_sync_repository.dart';

void main() {
  late FakeAccountRepository accounts;
  late FakeSyncRepository sync;
  late StreamController<void> changes;
  late SyncScheduler scheduler;

  setUp(() {
    accounts = FakeAccountRepository();
    sync = FakeSyncRepository();
    changes = StreamController<void>.broadcast();
    scheduler = SyncScheduler(
      accounts,
      sync,
      changes: changes.stream,
      delay: const Duration(milliseconds: 50),
    )..start();
  });

  tearDown(() => scheduler.dispose());

  test('sem conta, nada sobe', () async {
    changes.add(null);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(sync.synced, isEmpty);
  });

  test('entrar sincroniza', () async {
    // O agendador começa a ouvir a conta.
    await pumpEventQueue();
    await accounts.signInWithGoogle();
    await pumpEventQueue();

    expect(sync.synced, [FakeAccountRepository.google.uid]);
  });

  test('partidas em sequência viram um envio só', () async {
    await accounts.signInWithGoogle();
    await pumpEventQueue();
    sync.synced.clear();

    changes
      ..add(null)
      ..add(null)
      ..add(null);
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(sync.synced, hasLength(1));
  });

  test('sem rede, só quem pediu agora vê a falha', () async {
    sync.offline = true;
    await pumpEventQueue();
    // A sincronização de fundo ao entrar não deixa escapar o erro.
    await accounts.signInWithGoogle();
    await pumpEventQueue();

    await expectLater(
      scheduler.syncNow('google-uid'),
      throwsA(isA<SyncException>()),
    );
  });

  test('ao abrir o app com conta, sincroniza', () async {
    final opened = SyncScheduler(
      FakeAccountRepository(account: FakeAccountRepository.google),
      sync,
    )..start();
    addTearDown(opened.dispose);
    await pumpEventQueue();

    expect(sync.synced, [FakeAccountRepository.google.uid]);
  });
}
