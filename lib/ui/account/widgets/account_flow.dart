import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/account.dart';
import '../../../routing/routes.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/account_cubit.dart';

/// Depois de entrar: a conta com progresso mostra "Bem-vindo de volta"; a
/// nova (ou vazia) abre "Seu perfil" com o aviso de que o progresso deste
/// celular já está na conta; sem rede, segue direto. [from] é de
/// onde a conta foi aberta (`tour` ou `profile`). [replace]: quem chama é uma
/// tela da conta (o e-mail), que sai da pilha quando [from] é uma rota.
void continueAfterSignIn(
  BuildContext context,
  AccountState state,
  String from, {
  bool replace = false,
}) {
  final restored = state.restored;
  final target = restored != null
      ? Routes.accountRestoredFrom(from)
      : state.offline
      ? Routes.afterAccount(from)
      : Routes.accountDataFrom(from, welcome: true);
  if (!Routes.isRouteFrom(from)) {
    context.go(target, extra: restored);
    return;
  }
  // A conta aberta de uma rota (o convite antes da aula do link, T84) segue
  // por cima de quem a abriu: voltar do destino volta para lá.
  if (replace) {
    context.pushReplacement(target, extra: restored);
  } else {
    unawaited(context.push(target, extra: restored));
  }
}

/// O fim da conta (`Routes.afterAccount`): vinda de uma rota, o destino toma
/// o lugar da tela da conta, e quem abriu a conta fica por baixo.
void finishAccount(GoRouter router, String from) {
  final target = Routes.afterAccount(from);
  if (Routes.isRouteFrom(from)) {
    router.pushReplacement(target);
  } else {
    router.go(target);
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
