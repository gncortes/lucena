import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/account.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/firebase/auth_service.dart';
import '../../services/firebase/cloud_store_service.dart';
import '../../services/firebase/file_store_service.dart';
import '../../services/firebase/push_service.dart';
import '../../services/preferences_service.dart';
import 'avatar_repository.dart';

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

  /// Troca o nome da conta ("Seus dados"). Sem conta, nada acontece.
  Future<void> updateProfile({required String name});

  /// Sai da conta. Antes, tira da conta o token do push deste aparelho.
  Future<void> signOut();

  /// O push por conta: só o último aparelho em que a conta entrou recebe.
  /// Na abertura, grava o token se a conta ainda não tem nenhum ou se o
  /// token deste aparelho mudou; e acompanha as trocas do FCM. Não tira o
  /// lugar de um aparelho em que a conta entrou depois.
  Future<void> linkPushDevice();

  /// Apaga o perfil no Firestore e a conta no Auth. Com [photo] (o perfil
  /// tem foto enviada), apaga antes a foto no Storage.
  Future<void> deleteAccount({bool photo = false});
}

/// A conta no Firebase Auth, com o perfil em `users/{uid}` no Firestore.
class CloudAccountRepository implements AccountRepository {
  CloudAccountRepository(
    this._auth,
    this._store, {
    required this._avatars,
    required this._now,
    required this._language,
    this._push = const NoPushService(),
    this._preferences,
  });

  final AuthService _auth;
  final CloudStoreService _store;
  final AvatarRepository _avatars;
  final Now _now;

  /// O idioma escolhido no app (nulo: o do aparelho).
  final Future<String?> Function() _language;

  final PushService _push;

  /// Guarda `uid|token` do último token que este aparelho gravou na conta.
  final PreferencesService? _preferences;

  static const _pushKey = 'push.device';

  // Sair da conta não espera para sempre pelo Firestore.
  static const _pushTimeout = Duration(seconds: 5);

  /// O tamanho máximo do nome nas regras do Firestore.
  static const maxName = 80;

  @override
  Account? get current => _auth.current;

  @override
  Stream<Account?> get changes => _auth.changes;

  @override
  Future<Account?> signInWithGoogle() async {
    final account = await _auth.signInWithGoogle();
    if (account != null) _signedIn(account);
    return account;
  }

  @override
  Future<Account> signInWithEmail(String email, String password) async {
    final account = await _auth.signInWithEmail(email, password);
    _signedIn(account);
    return account;
  }

  @override
  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    final account = await _auth.createWithEmail(email, password, name: name);
    _signedIn(account, created: true);
    return account;
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);

  @override
  Future<void> updateProfile({required String name}) async {
    final account = _auth.current;
    if (account == null) return;
    _touchProfile(account, name: name);
  }

  @override
  Future<void> signOut() async {
    final uid = _auth.current?.uid;
    if (uid != null) await _releasePush(uid);
    await _auth.signOut();
  }

  @override
  Future<void> linkPushDevice() async {
    if (!_push.available || _preferences == null) return;
    _tokenChanges ??= _push.tokenChanges.listen((token) {
      final uid = _auth.current?.uid;
      if (uid != null) unawaited(_refreshPush(uid, token));
    });
    final uid = _auth.current?.uid;
    if (uid == null) return;
    try {
      final token = await _push.token();
      if (token != null) await _refreshPush(uid, token);
    } on Object catch (error) {
      debugPrint('Push sem token: $error');
    }
  }

  StreamSubscription<String>? _tokenChanges;

  void _signedIn(Account account, {bool created = false}) {
    _touchProfile(account, created: created);
    unawaited(_claimPush(account.uid));
  }

  // Entrou na conta: este aparelho passa a ser o do push, no lugar do outro.
  Future<void> _claimPush(String uid) async {
    final preferences = _preferences;
    if (!_push.available || preferences == null) return;
    try {
      final token = await _push.token();
      if (token == null) return;
      await preferences.setString(_pushKey, '$uid|$token');
      await _store.writePushToken(uid, token, _now());
    } on Object catch (error) {
      debugPrint('Push sem token na conta: $error');
    }
  }

  Future<void> _refreshPush(String uid, String token) async {
    final preferences = _preferences;
    if (preferences == null) return;
    final saved = await preferences.getString(_pushKey);
    if (saved == '$uid|$token') return;
    try {
      final remote = await _store.readPushToken(uid);
      final mine = saved != null && saved == '$uid|$remote';
      // Sem token na conta (versão antiga) ou ainda o deste aparelho.
      if (remote != null && !mine) return;
      await preferences.setString(_pushKey, '$uid|$token');
      await _store.writePushToken(uid, token, _now());
    } on Object catch (error) {
      debugPrint('Push sem token na conta: $error');
    }
  }

  // Saiu da conta: o token sai junto, se ainda for o deste aparelho.
  Future<void> _releasePush(String uid) async {
    final preferences = _preferences;
    if (preferences == null) return;
    final saved = await preferences.getString(_pushKey);
    await preferences.remove(_pushKey);
    if (saved == null || !saved.startsWith('$uid|')) return;
    try {
      await () async {
        final remote = await _store.readPushToken(uid);
        if (saved == '$uid|$remote') await _store.deletePushToken(uid);
      }().timeout(_pushTimeout);
    } on Object catch (error) {
      debugPrint('Push sem apagar o token: $error');
    }
  }

  @override
  Future<void> deleteAccount({bool photo = false}) async {
    final account = _auth.current;
    if (account == null) return;
    try {
      // Sem foto enviada o Storage nem é tocado (pode nem estar ativo).
      if (photo) await _avatars.delete(account.uid);
      await _store.deleteUser(account.uid);
    } on FileStoreException {
      throw const AccountException(AccountFailure.network);
    } on CloudStoreException {
      // Sem rede não dá para apagar o que está na nuvem: nada é apagado.
      throw const AccountException(AccountFailure.network);
    }
    await _preferences?.remove(_pushKey);
    await _auth.delete();
  }

  // A gravação do Firestore só termina quando o servidor confirma; sem rede
  // ela fica na fila do aparelho. O login não espera por ela.
  void _touchProfile(Account account, {bool created = false, String? name}) {
    final now = _now();
    final trimmed = (name ?? account.name)?.trim();
    unawaited(() async {
      try {
        final language = await _language();
        await _store.mergeUser(account.uid, {
          if (trimmed != null && trimmed.isNotEmpty)
            'name': trimmed.length > maxName
                ? trimmed.substring(0, maxName)
                : trimmed,
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
