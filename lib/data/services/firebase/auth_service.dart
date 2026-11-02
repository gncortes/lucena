import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../domain/models/account.dart';

/// A conta pelo Firebase Auth: Google ou e-mail e senha.
///
/// Os erros saem como [AccountException], já traduzidos para
/// [AccountFailure].
abstract class AuthService {
  /// A conta atual, ou nula sem login.
  Account? get current;

  /// Muda a cada entrada e saída (e já começa com a atual).
  Stream<Account?> get changes;

  /// Abre a escolha de conta do Google. Nulo: a pessoa cancelou.
  Future<Account?> signInWithGoogle();

  Future<Account> signInWithEmail(String email, String password);

  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// Reautentica o Google antes de [deleteData] e serializa mudanças de
  /// sessão até apagar o Auth. False: seleção cancelada.
  /// Em divergência, [beforeSignOut] libera recursos da sessão atual sob
  /// o mesmo bloqueio. Uma falha dessa limpeza não impede tentar o logout.
  Future<bool> delete({
    required String expectedUid,
    required Future<void> Function() deleteData,
    required Future<void> Function(String uid) beforeSignOut,
  });
}

/// Build sem Firebase: nada de conta, e cada tentativa diz que não está
/// disponível.
class NoAuthService implements AuthService {
  const NoAuthService();

  static const _unavailable = AccountException(AccountFailure.unavailable);

  @override
  Account? get current => null;

  @override
  Stream<Account?> get changes => Stream.value(null);

  @override
  Future<Account?> signInWithGoogle() => Future.error(_unavailable);

  @override
  Future<Account> signInWithEmail(String email, String password) =>
      Future.error(_unavailable);

  @override
  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  }) => Future.error(_unavailable);

  @override
  Future<void> sendPasswordReset(String email) => Future.error(_unavailable);

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> delete({
    required String expectedUid,
    required Future<void> Function() deleteData,
    required Future<void> Function(String uid) beforeSignOut,
  }) => Future.error(_unavailable);
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  // O google_sign_in 7 pede um `initialize` antes de tudo, uma vez só. No
  // Android o id do cliente vem do `google-services.json`.
  Future<void>? _googleReady;

  // O plugin Android resolve currentUser nativo ao receber o comando. Só
  // capturar User no Dart não impede um login/logout entre os awaits.
  Future<void> _pendingAuth = Future.value();

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _pendingAuth.then((_) => action());
    _pendingAuth = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  @override
  Account? get current => _account(_auth.currentUser);

  @override
  Stream<Account?> get changes => _auth.authStateChanges().map(_account);

  @override
  Future<Account?> signInWithGoogle() => _exclusive(
    () => _guard(() async {
      final credential = await _googleCredential();
      if (credential == null) return null;
      final result = await _auth.signInWithCredential(credential);
      return _account(result.user);
    }),
  );

  Future<AuthCredential?> _googleCredential() async {
    await (_googleReady ??= _google.initialize());
    final GoogleSignInAccount user;
    try {
      user = await _google.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      throw const AccountException(AccountFailure.unknown);
    }
    final token = user.authentication.idToken;
    if (token == null) throw const AccountException(AccountFailure.unknown);
    return GoogleAuthProvider.credential(idToken: token);
  }

  @override
  Future<Account> signInWithEmail(String email, String password) => _exclusive(
    () => _guard(() async {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _account(result.user)!;
    }),
  );

  @override
  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  }) => _exclusive(
    () => _guard(() async {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user!;
      // A confirmação do endereço vai por e-mail; a pessoa joga enquanto isso
      // (regra 11), então a conta não espera por ela.
      unawaited(
        user.sendEmailVerification().catchError(
          (Object error) => debugPrint('Confirmação não enviada: $error'),
        ),
      );
      final trimmed = name?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        await user.updateDisplayName(trimmed);
        await user.reload();
      }
      return _account(_auth.currentUser ?? user)!;
    }),
  );

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _exclusive(() => _guard(_signOut));

  Future<void> _signOut() async {
    // A falha de um provedor não pode impedir a tentativa no outro.
    Object? failure;
    StackTrace? trace;
    try {
      await _auth.signOut();
    } on Object catch (error, stack) {
      failure = error;
      trace = stack;
    }
    try {
      if (_googleReady != null) await _google.signOut();
    } on Object catch (error, stack) {
      failure ??= error;
      trace ??= stack;
    }
    if (failure != null) Error.throwWithStackTrace(failure, trace!);
  }

  @override
  Future<bool> delete({
    required String expectedUid,
    required Future<void> Function() deleteData,
    required Future<void> Function(String uid) beforeSignOut,
  }) => _exclusive(() async {
    try {
      return await _guard(() async {
        final user = _requireUser(expectedUid);
        if (_account(user)!.provider == AccountProvider.google) {
          final credential = await _googleCredential();
          _requireUser(expectedUid);
          if (credential == null) return false;
          final result = await user.reauthenticateWithCredential(credential);
          if (result.user?.uid != expectedUid) {
            throw const AccountException(AccountFailure.userMismatch);
          }
          _requireUser(expectedUid);
        }
        await deleteData();
        _requireUser(expectedUid);
        await user.delete();
        // A conta já foi apagada; revogar o acesso Google é limpeza auxiliar.
        try {
          if (_googleReady != null) await _google.disconnect();
        } on Object {
          debugPrint('Conta apagada; revogação Google pendente.');
        }
        return true;
      });
    } on AccountException catch (error) {
      if (error.failure == AccountFailure.userMismatch) {
        // Ainda sob exclusão mútua: nenhum login pode escapar da limpeza.
        final uid = _auth.currentUser?.uid;
        try {
          if (uid != null) await beforeSignOut(uid);
        } on Object {
          debugPrint('Conta diferente; limpeza da sessão não concluída.');
        }
        try {
          await _signOut();
        } on Object {
          debugPrint('Conta diferente; saída não concluída.');
        }
      }
      rethrow;
    }
  });

  User _requireUser(String expectedUid) {
    final user = _auth.currentUser;
    if (user == null || user.uid != expectedUid) {
      throw const AccountException(AccountFailure.userMismatch);
    }
    return user;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (error) {
      throw AccountException(_failure(error.code));
    }
  }

  static Account? _account(User? user) {
    if (user == null) return null;
    final google = user.providerData.any(
      (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID,
    );
    return Account(
      uid: user.uid,
      provider: google ? AccountProvider.google : AccountProvider.email,
      email: user.email,
      name: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  static AccountFailure _failure(String code) => switch (code) {
    'invalid-email' => AccountFailure.invalidEmail,
    'weak-password' => AccountFailure.weakPassword,
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => AccountFailure.wrongCredentials,
    'email-already-in-use' ||
    'account-exists-with-different-credential' => AccountFailure.emailInUse,
    'too-many-requests' => AccountFailure.tooManyAttempts,
    'network-request-failed' => AccountFailure.network,
    'requires-recent-login' => AccountFailure.recentLoginRequired,
    'user-mismatch' || 'no-current-user' => AccountFailure.userMismatch,
    'operation-not-allowed' => AccountFailure.unavailable,
    _ => AccountFailure.unknown,
  };
}
