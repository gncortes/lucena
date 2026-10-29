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
  final _changes = StreamController<Account?>.broadcast();

  static const google = Account(
    uid: 'google-uid',
    provider: AccountProvider.google,
    email: 'teste@example.com',
    name: 'Teste',
  );

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

  @override
  Future<void> signOut() async => _set(null);

  /// Quantas vezes o app ligou o push da conta na abertura.
  int pushLinks = 0;

  @override
  Future<void> linkPushDevice() async => pushLinks++;

  @override
  Future<void> deleteAccount({bool photo = false}) async {
    _throwIfFailing();
    deletedWithPhoto = photo;
    _set(null);
  }
}
