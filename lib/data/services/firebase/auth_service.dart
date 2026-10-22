import 'package:firebase_auth/firebase_auth.dart';
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

  /// Apaga a conta do Auth (os dados do Firestore saem antes, no
  /// repositório).
  Future<void> delete();
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
  Future<void> delete() => Future.error(_unavailable);
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

  @override
  Account? get current => _account(_auth.currentUser);

  @override
  Stream<Account?> get changes => _auth.authStateChanges().map(_account);

  @override
  Future<Account?> signInWithGoogle() async {
    try {
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
      final result = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
      return _account(result.user);
    } on FirebaseAuthException catch (error) {
      throw AccountException(_failure(error.code));
    }
  }

  @override
  Future<Account> signInWithEmail(String email, String password) =>
      _guard(() async {
        final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        return _account(result.user)!;
      });

  @override
  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  }) => _guard(() async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = result.user!;
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      await user.updateDisplayName(trimmed);
      await user.reload();
    }
    return _account(_auth.currentUser ?? user)!;
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    if (_googleReady != null) await _google.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> delete() => _guard(() async {
    await _auth.currentUser?.delete();
    if (_googleReady != null) await _google.disconnect();
  });

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
    'operation-not-allowed' => AccountFailure.unavailable,
    _ => AccountFailure.unknown,
  };
}
