import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/services/firebase/auth_service.dart';
import 'package:lucena/data/services/firebase/push_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_avatar_repository.dart';
import '../../../../testing/fakes/fake_cloud_store_service.dart';
import '../../../../testing/fakes/fake_now.dart';

const _ana = Account(uid: 'u1', provider: AccountProvider.google, name: 'Ana');

class _Auth extends NoAuthService {
  Account? signedIn;

  @override
  Account? get current => signedIn;

  @override
  Future<Account?> signInWithGoogle() async => signedIn = _ana;

  @override
  Future<void> signOut() async => signedIn = null;
}

class _Push extends NoPushService {
  String? current = 'token-a';
  final changes = StreamController<String>.broadcast();

  @override
  bool get available => true;

  @override
  Future<String?> token() async => current;

  @override
  Stream<String> get tokenChanges => changes.stream;
}

void main() {
  final now = FakeNow(DateTime.utc(2026, 10, 24, 12));
  late _Auth auth;
  late _Push push;
  late FakeCloudStoreService store;

  CloudAccountRepository repository() => CloudAccountRepository(
    auth,
    store,
    avatars: FakeAvatarRepository(),
    now: now,
    language: () async => 'pt',
    push: push,
    preferences: PreferencesService(),
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    auth = _Auth();
    push = _Push();
    store = FakeCloudStoreService();
  });

  test('entrar grava o token deste aparelho na conta', () async {
    await repository().signInWithGoogle();
    await pumpEventQueue();

    expect(store.pushTokens, {'u1': 'token-a'});
  });

  test('entrar em outro aparelho troca o token: só o último recebe', () async {
    store.pushTokens['u1'] = 'token-velho';

    await repository().signInWithGoogle();
    await pumpEventQueue();

    expect(store.pushTokens, {'u1': 'token-a'});
  });

  test('sair da conta apaga o token', () async {
    final accounts = repository();
    await accounts.signInWithGoogle();
    await pumpEventQueue();

    await accounts.signOut();

    expect(store.pushTokens, isEmpty);
    expect(auth.signedIn, isNull);
  });

  test('sair não apaga o token de um aparelho que entrou depois', () async {
    final accounts = repository();
    await accounts.signInWithGoogle();
    await pumpEventQueue();
    store.pushTokens['u1'] = 'token-b';

    await accounts.signOut();

    expect(store.pushTokens, {'u1': 'token-b'});
  });

  test('a abertura não tira o lugar do aparelho que entrou depois', () async {
    await repository().signInWithGoogle();
    await pumpEventQueue();
    store.pushTokens['u1'] = 'token-b';
    push.current = 'token-a2';

    await repository().linkPushDevice();

    expect(store.pushTokens, {'u1': 'token-b'});
  });

  test('a abertura grava o token de quem já estava logado', () async {
    auth.signedIn = _ana;

    await repository().linkPushDevice();

    expect(store.pushTokens, {'u1': 'token-a'});
  });

  test('o token novo do FCM troca o deste aparelho na conta', () async {
    final accounts = repository();
    await accounts.signInWithGoogle();
    await pumpEventQueue();
    await accounts.linkPushDevice();

    push.changes.add('token-a2');
    await pumpEventQueue();

    expect(store.pushTokens, {'u1': 'token-a2'});
  });

  test('sem o Firebase não grava nada', () async {
    final accounts = CloudAccountRepository(
      auth,
      store,
      avatars: FakeAvatarRepository(),
      now: now,
      language: () async => 'pt',
      preferences: PreferencesService(),
    );
    await accounts.signInWithGoogle();
    await accounts.linkPushDevice();
    await pumpEventQueue();

    expect(store.pushTokens, isEmpty);
  });
}
