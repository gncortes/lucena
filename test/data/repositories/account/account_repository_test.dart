import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/services/firebase/auth_service.dart';
import 'package:lucena/data/services/firebase/cloud_store_service.dart';
import 'package:lucena/domain/models/account.dart';

import '../../../../testing/fakes/fake_now.dart';

const _google = Account(
  uid: 'u1',
  provider: AccountProvider.google,
  name: 'Ana',
);

class _Auth extends NoAuthService {
  Account? signedIn;
  Account? google = _google;
  bool deleted = false;

  @override
  Account? get current => signedIn;

  @override
  Future<Account?> signInWithGoogle() async => signedIn = google;

  @override
  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  }) async => signedIn = Account(
    uid: 'u2',
    provider: AccountProvider.email,
    email: email,
    name: name,
  );

  @override
  Future<void> delete() async => deleted = true;
}

class _Store implements CloudStoreService {
  final merged = <String, Map<String, Object?>>{};
  final deleted = <String>[];

  /// Sem rede: a gravação não termina.
  bool offline = false;

  @override
  Future<void> mergeUser(String uid, Map<String, Object?> data) {
    if (offline) return Completer<void>().future;
    merged[uid] = data;
    return Future.value();
  }

  @override
  Future<void> deleteUser(String uid) async => deleted.add(uid);
}

void main() {
  final now = FakeNow(DateTime.utc(2026, 10, 22, 12));
  late _Auth auth;
  late _Store store;
  late CloudAccountRepository repository;

  setUp(() {
    auth = _Auth();
    store = _Store();
    repository = CloudAccountRepository(
      auth,
      store,
      now: now,
      language: () async => 'pt',
    );
  });

  test('entrar com o Google grava o perfil com nome e idioma', () async {
    expect(await repository.signInWithGoogle(), _google);
    await pumpEventQueue();

    expect(store.merged['u1'], {
      'name': 'Ana',
      'language': 'pt',
      'updatedAt': now.value,
    });
  });

  test('a escolha de conta fechada não grava nada', () async {
    auth.google = null;

    expect(await repository.signInWithGoogle(), isNull);
    await pumpEventQueue();

    expect(store.merged, isEmpty);
  });

  test('criar a conta marca a data de criação', () async {
    await repository.createWithEmail('a@b.com', 'segredo1', name: 'Bia');
    await pumpEventQueue();

    expect(store.merged['u2']?['createdAt'], now.value);
  });

  test('sem rede o login não espera o perfil', () async {
    store.offline = true;

    await expectLater(
      repository.signInWithGoogle().timeout(const Duration(seconds: 1)),
      completion(_google),
    );
  });

  test('apagar a conta apaga o perfil antes da conta', () async {
    await repository.signInWithGoogle();

    await repository.deleteAccount();

    expect(store.deleted, ['u1']);
    expect(auth.deleted, isTrue);
  });

  test('sem conta, apagar não faz nada', () async {
    await repository.deleteAccount();

    expect(store.deleted, isEmpty);
    expect(auth.deleted, isFalse);
  });

  test('sem Firebase, entrar falha como indisponível', () async {
    final offline = CloudAccountRepository(
      const NoAuthService(),
      const NoCloudStoreService(),
      now: now,
      language: () async => null,
    );

    await expectLater(
      offline.signInWithGoogle(),
      throwsA(
        isA<AccountException>().having(
          (e) => e.failure,
          'failure',
          AccountFailure.unavailable,
        ),
      ),
    );
  });
}
