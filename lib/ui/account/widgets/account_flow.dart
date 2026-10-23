import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/account.dart';
import '../../../routing/routes.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/account_cubit.dart';

/// Depois de entrar: a conta com progresso mostra "Bem-vindo de volta"; a
/// nova (ou vazia) abre "Seu perfil" com o aviso de que o progresso deste
/// celular já está na conta; sem rede, segue direto. [from] é de
/// onde a conta foi aberta (`tour` ou `profile`).
void continueAfterSignIn(
  BuildContext context,
  AccountState state,
  String from,
) {
  final restored = state.restored;
  if (restored != null) {
    context.go(Routes.accountRestoredFrom(from), extra: restored);
  } else if (state.offline) {
    context.go(Routes.afterAccount(from));
  } else {
    context.go(Routes.accountDataFrom(from, welcome: true));
  }
}

/// O aviso de uma entrada que não deu certo.
String accountFailureText(AppLocalizations l10n, AccountFailure failure) =>
    switch (failure) {
      AccountFailure.unavailable => l10n.accountSoon,
      AccountFailure.network => l10n.accountFailedNetwork,
      AccountFailure.invalidEmail => l10n.accountInvalidEmail,
      AccountFailure.weakPassword => l10n.accountWeakPassword,
      AccountFailure.wrongCredentials => l10n.accountWrongCredentials,
      AccountFailure.emailInUse => l10n.accountEmailInUse,
      AccountFailure.tooManyAttempts => l10n.accountTooManyAttempts,
      _ => l10n.accountFailed,
    };
