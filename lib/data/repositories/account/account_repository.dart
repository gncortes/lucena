import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/account.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/firebase/auth_service.dart';
import '../../services/firebase/cloud_store_service.dart';

/// A conta opcional (E1.13): entrar com o Google ou com e-mail e senha, sair e
/// apagar a conta (exigência da Play).
///
/// Sem conta o app funciona inteiro, só neste aparelho.
abstract class AccountRepository {
  Account? get current;

  /// Muda a cada entrada e saída (e já começa com a atual).
  Stream<Account?> get changes;

  /// Nulo: a pessoa fechou a escolha de conta do Google.
  Future<Account?> signInWithGoogle();

  Future<Account> signInWithEmail(String email, String password);

  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// Apaga o perfil no Firestore e a conta no Auth.
  Future<void> deleteAccount();
}

/// A conta no Firebase Auth, com o perfil em `users/{uid}` no Firestore.
class CloudAccountRepository implements AccountRepository {
  const CloudAccountRepository(
    this._auth,
    this._store, {
    required this._now,
    required this._language,
  });

  final AuthService _auth;
  final CloudStoreService _store;
  final Now _now;

  /// O idioma escolhido no app (nulo: o do aparelho).
  final Future<String?> Function() _language;

  @override
  Account? get current => _auth.current;

  @override
  Stream<Account?> get changes => _auth.changes;

  @override
  Future<Account?> signInWithGoogle() async {
    final account = await _auth.signInWithGoogle();
    if (account != null) _touchProfile(account);
    return account;
  }

  @override
  Future<Account> signInWithEmail(String email, String password) async {
    final account = await _auth.signInWithEmail(email, password);
    _touchProfile(account);
    return account;
  }

  @override
  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    final account = await _auth.createWithEmail(email, password, name: name);
    _touchProfile(account, created: true);
    return account;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount() async {
    final account = _auth.current;
    if (account == null) return;
    await _store.deleteUser(account.uid);
    await _auth.delete();
  }

  // A gravação do Firestore só termina quando o servidor confirma; sem rede
  // ela fica na fila do aparelho. O login não espera por ela.
  void _touchProfile(Account account, {bool created = false}) {
    final now = _now();
    unawaited(() async {
      try {
        final language = await _language();
        await _store.mergeUser(account.uid, {
          'name': ?account.name,
          'language': ?language,
          'updatedAt': now,
          if (created) 'createdAt': now,
        });
      } on Object catch (error) {
        debugPrint('Perfil não gravado: $error');
      }
    }());
  }
}
