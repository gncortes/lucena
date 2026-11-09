import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../domain/models/account.dart';

/// A conta na linha da pessoa das Configurações: a de agora e, depois, cada
/// troca (entrar, sair). Nula: sem conta.
class SettingsAccountCubit extends Cubit<Account?> {
  SettingsAccountCubit(AccountRepository accounts) : super(accounts.current) {
    _subscription = accounts.changes.listen((account) {
      if (!isClosed) emit(account);
    });
  }

  late final StreamSubscription<Account?> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
