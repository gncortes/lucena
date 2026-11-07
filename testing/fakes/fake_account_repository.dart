import 'dart:async';

import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/domain/models/account.dart';

/// Uma conta em memória. [failure] faz a próxima entrada falhar; [canceled]
/// faz a escolha do Google voltar sem conta.
class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository({this.account});

  Account? account;
  AccountFailure? failure;
  bool canceled = false;

  /// Segura a entrada pelo Google até completar (para ver o carregando).
  Completer<void>? googleHold;
  final _changes = StreamController<Account?>.broadcast();

  static const google = Account(
    uid: 'google-uid',
    provider: AccountProvider.google,
    email: 'teste@example.com',
    name: 'Teste',
  );

  /// A conta foi suspensa pelo admin (`bloqueios/{uid}`). Mudar com o app
  /// aberto avisa quem acompanha ao vivo ([blockedChanges]).
  bool get blocked => _blocked;
  set blocked(bool value) {
    _blocked = value;
    _blockedChanges.add(value);
  }

  bool _blocked = false;
  final _blockedChanges = StreamController<bool>.broadcast();

  @override
  Stream<bool> blockedChanges(String uid) async* {
    bool of(bool value) => account?.uid == uid && value;
    yield of(_blocked);
    yield* _blockedChanges.stream.map(of);
  }

  @override
  Account? get current => account;

  @override
  Stream<Account?> get changes async* {
    yield account;
    yield* _changes.stream;
  }

  void _set(Account? value) {
    account = value;
    _changes.add(value);
  }

  void _throwIfFailing() {
    final failing = failure;
    if (failing != null) throw AccountException(failing);
  }

  @override
  Future<Account?> signInWithGoogle() async {
    final hold = googleHold;
    if (hold != null) await hold.future;
    _throwIfFailing();
    if (canceled) return null;
    _set(google);
    return google;
  }

  @override
  Future<Account> signInWithEmail(String email, String password) async {
    _throwIfFailing();
    final account = Account(
      uid: 'email-uid',
      provider: AccountProvider.email,
      email: email,
    );
    _set(account);
    return account;
  }

  @override
  Future<Account> createWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    _throwIfFailing();
    final account = Account(
      uid: 'email-uid',
      provider: AccountProvider.email,
      email: email,
      name: name,
    );
    _set(account);
    return account;
  }

  final List<String> resets = [];

  /// O `photo` do último [deleteAccount].
  bool? deletedWithPhoto;
  final deletedUids = <String>[];

  @override
  Future<void> sendPasswordReset(String email) async {
    _throwIfFailing();
    resets.add(email);
  }

  final List<String> names = [];

  @override
  Future<void> updateProfile({required String name}) async {
    if (account == null) return;
    names.add(name);
    final current = account!;
    _set(
      Account(
        uid: current.uid,
        provider: current.provider,
        email: current.email,
        name: name,
        photoUrl: current.photoUrl,
      ),
    );
  }

  /// Com valor, a próxima saída falha (e a conta fica).
  Object? signOutError;

  /// Quantas vezes o app pediu para sair.
  int signOuts = 0;

  @override
  Future<void> signOut() async {
    signOuts++;
    final error = signOutError;
    if (error != null) {
      signOutError = null;
      throw error;
    }
    _set(null);
  }

  /// Quantas vezes o app ligou o push da conta na abertura.
  int pushLinks = 0;

  @override
  Future<void> linkPushDevice() async => pushLinks++;

  @override
  Future<bool> deleteAccount({
    required String expectedUid,
    bool photo = false,
  }) async {
    if (account?.uid != expectedUid) {
      _set(null);
      throw const AccountException(AccountFailure.userMismatch);
    }
    _throwIfFailing();
    if (canceled) return false;
    deletedWithPhoto = photo;
    deletedUids.add(expectedUid);
    _set(null);
    return true;
  }
}
