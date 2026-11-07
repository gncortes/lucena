import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/services/firebase/auth_service.dart';
import 'package:lucena/data/services/firebase/push_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/account.dart';
import 'package:lucena/domain/models/push_permission.dart';
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
  PushPermission granted = PushPermission.allowed;
  var deleted = 0;
  final changes = StreamController<String>.broadcast();

  @override
  bool get available => true;

  @override
  Future<String?> token() async => current;

  @override
  Stream<String> get tokenChanges => changes.stream;

  @override
  Future<PushPermission> permission() async => granted;

  @override
  Future<void> deleteToken() async {
    deleted++;
    current = 'token-novo-$deleted';
  }
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

  group('H-R5-60 · estado das notificações', () {
    for (final permission in PushPermission.values) {
      test('a abertura grava ${permission.wire} com a hora do Now', () async {
        auth.signedIn = _ana;
        push.granted = permission;

        await repository().linkPushDevice();

        final status = store.pushStatus['u1']!;
        expect(status.permission, permission);
        expect(status.checkedAt, now());
        expect(status.openedAt, now());
        expect(status.toFirestore(), {
          'permissao': permission.wire,
          'conferidoEm': now(),
          'ultimaAbertura': now(),
        });
      });
    }

    test('outra abertura atualiza a hora', () async {
      auth.signedIn = _ana;
      await repository().linkPushDevice();
      final before = now.value;
      addTearDown(() => now.value = before);
      now.value = DateTime.utc(2026, 10, 25, 9);

      await repository().linkPushDevice();

      expect(store.pushStatus['u1']!.openedAt, DateTime.utc(2026, 10, 25, 9));
    });

    test('aparelho que não é o do push da conta não grava', () async {
      await repository().signInWithGoogle();
      await pumpEventQueue();
      store.pushTokens['u1'] = 'token-b';
      store.pushStatus.clear();
      push.current = 'token-a2';

      await repository().linkPushDevice();

      expect(store.pushStatus, isEmpty);
    });

    test(
      'outro aparelho tomou a conta com o mesmo token salvo aqui: não grava',
      () async {
        auth.signedIn = _ana;
        await repository().linkPushDevice();
        store.pushStatus.clear();
        store.pushTokens['u1'] = 'token-b';

        await repository().linkPushDevice();

        expect(store.pushStatus, isEmpty);
      },
    );

    test('sem rede não grava (nem cria documento sem token)', () async {
      auth.signedIn = _ana;
      await repository().linkPushDevice();
      store.pushStatus.clear();
      store.offline = true;

      await repository().linkPushDevice();

      expect(store.pushStatus, isEmpty);
    });

    test('sem conta não grava', () async {
      await repository().linkPushDevice();

      expect(store.pushStatus, isEmpty);
    });

    test('sem token (sem Google Play) não grava', () async {
      auth.signedIn = _ana;
      push.current = null;

      await repository().linkPushDevice();

      expect(store.pushStatus, isEmpty);
    });
  });

  group('H-R5-64 · sair da conta apaga o token', () {
    test('sair apaga push/device e troca o token do FCM', () async {
      final accounts = repository();
      await accounts.signInWithGoogle();
      await accounts.linkPushDevice();
      await pumpEventQueue();

      await accounts.signOut();

      expect(store.pushTokens, isEmpty);
      expect(store.pushStatus, isEmpty);
      expect(push.deleted, 1);
    });

    test('sem rede: o token velho fica na conta, mas é invalidado', () async {
      final accounts = repository();
      await accounts.signInWithGoogle();
      await pumpEventQueue();
      store.offline = true;

      await accounts.signOut();

      expect(store.pushTokens, {'u1': 'token-a'});
      expect(push.deleted, 1);
      expect(push.current, isNot('token-a'));
    });

    test(
      'outro uid que entra no aparelho não recebe o push do anterior',
      () async {
        final accounts = repository();
        await accounts.signInWithGoogle();
        await pumpEventQueue();
        await accounts.signOut();

        auth.signedIn = const Account(
          uid: 'u2',
          provider: AccountProvider.google,
          name: 'Bia',
        );
        await accounts.linkPushDevice();

        expect(store.pushTokens.containsKey('u1'), isFalse);
        expect(store.pushTokens['u2'], isNot('token-a'));
      },
    );
  });
}
