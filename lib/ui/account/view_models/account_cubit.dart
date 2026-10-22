import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../data/repositories/sync/sync_scheduler.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/onboarding.dart';

/// A entrada com conta: Google ou e-mail. [failure] vale por um aviso: a
/// tela mostra e o estado volta ao normal na próxima ação.
class AccountState {
  const AccountState({
    this.busy = false,
    this.done = false,
    this.created = false,
    this.restored,
    this.offline = false,
    this.failure,
  });

  final bool busy;

  /// Entrou: a tela segue.
  final bool done;

  /// A conta é nova (criada agora com e-mail): segue para "Seu perfil".
  final bool created;

  /// A conta já tinha progresso, agora junto com o do aparelho: segue para
  /// "Bem-vindo de volta". Nulo: a conta estava vazia ou sem rede.
  final SyncResult? restored;

  /// Entrou, mas sem rede a conta não foi lida (sobe depois, sozinho).
  final bool offline;
  final AccountFailure? failure;
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._accounts, {this._onboarding, this._sync})
    : super(const AccountState());

  final AccountRepository _accounts;
  final OnboardingRepository? _onboarding;

  /// Sem ele (testes antigos), entrar não lê a conta.
  final SyncScheduler? _sync;

  /// A senha mínima (a tela diz "pelo menos 8 caracteres"; o Firebase
  /// aceitaria 6).
  static const minPassword = 8;

  /// A tela abriu. Na primeira abertura, o app fechado aqui volta aqui.
  Future<void> enter() async {
    final repository = _onboarding;
    if (repository == null) return;
    final onboarding = await repository.load();
    if (onboarding.done) return;
    await repository.save(onboarding.copyWith(stage: OnboardingStage.account));
  }

  Future<void> signInWithGoogle() => _run(_accounts.signInWithGoogle);

  Future<void> signInWithEmail(String email, String password) =>
      _run(() => _accounts.signInWithEmail(email.trim(), password));

  Future<void> createWithEmail(String email, String password) {
    if (password.length < minPassword) {
      emit(const AccountState(failure: AccountFailure.weakPassword));
      return Future.value();
    }
    return _run(
      () => _accounts.createWithEmail(email.trim(), password),
      created: true,
    );
  }

  /// "Mandar o link" de senha nova. A resposta é a mesma com ou sem conta
  /// (ninguém descobre quais e-mails têm conta). Nulo: mandou; senão, o
  /// motivo (e-mail mal escrito, sem rede).
  Future<AccountFailure?> sendPasswordReset(String email) async {
    try {
      await _accounts.sendPasswordReset(email.trim());
      return null;
    } on AccountException catch (error) {
      return error.failure == AccountFailure.wrongCredentials
          ? null
          : error.failure;
    }
  }

  Future<void> _run(
    Future<Account?> Function() signIn, {
    bool created = false,
  }) async {
    if (state.busy) return;
    emit(const AccountState(busy: true));
    try {
      final account = await signIn();
      if (account == null) {
        if (!isClosed) emit(const AccountState());
        return;
      }
      final (restored, offline) = await _read(account, created: created);
      if (!isClosed) {
        emit(
          AccountState(
            done: true,
            created: created,
            restored: restored,
            offline: offline,
          ),
        );
      }
    } on AccountException catch (error) {
      if (!isClosed) emit(AccountState(failure: error.failure));
    }
  }

  // Junta a conta com o aparelho (regra 13). Uma conta criada agora está
  // vazia: só sobe, sem tela de "Bem-vindo de volta".
  Future<(SyncResult?, bool)> _read(
    Account account, {
    required bool created,
  }) async {
    final sync = _sync;
    if (sync == null) return (null, false);
    try {
      final result = await sync.syncNow(account.uid);
      return (!created && result.hadRemote ? result : null, false);
    } on SyncException {
      return (null, true);
    }
  }

  /// "Seu perfil" salvo com conta: o nome vai para a conta e o progresso
  /// sobe. Sem esperar: sem rede, sobe depois, sozinho.
  void publishProfile(String name) {
    final account = _accounts.current;
    if (account == null) return;
    unawaited(
      _accounts.updateProfile(name: name.trim()).catchError((Object _) {}),
    );
    final sync = _sync;
    if (sync != null) {
      unawaited(
        sync.syncNow(account.uid).then<void>((_) {}, onError: (Object _) {}),
      );
    }
  }
}
