import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../domain/models/account.dart';

/// A entrada com conta da tela "Quer guardar seu progresso?". [failure] vale
/// por um aviso: a tela mostra e o estado volta ao normal na próxima ação.
class AccountState {
  const AccountState({this.busy = false, this.done = false, this.failure});

  final bool busy;

  /// Entrou: a tela segue para "Seu nível".
  final bool done;
  final AccountFailure? failure;
}

class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._accounts) : super(const AccountState());

  final AccountRepository _accounts;

  Future<void> signInWithGoogle() async {
    if (state.busy) return;
    emit(const AccountState(busy: true));
    try {
      final account = await _accounts.signInWithGoogle();
      if (!isClosed) emit(AccountState(done: account != null));
    } on AccountException catch (error) {
      if (!isClosed) emit(AccountState(failure: error.failure));
    }
  }
}
