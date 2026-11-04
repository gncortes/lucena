import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/account.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/lucena_snack_bar.dart';
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
  // A conta nova aceita os Termos e a Política antes de seguir (H-CON-08).
  final target = state.needsConsent
      ? Routes.accountConsentFrom(from, offline: state.offline)
      : restored != null
      ? Routes.accountRestoredFrom(from)
      : afterConsent(from, offline: state.offline);
  if (_isTraining(from) && !state.needsConsent) {
    context.go(from);
    return;
  }
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

/// Para onde a conta nova segue depois do aceite: o treino que abriu a conta
/// (o portão do pacote retoma na hora); sem rede, o fim da conta; senão,
/// "Seu perfil" com o aviso de boas-vindas.
String afterConsent(String from, {required bool offline}) => _isTraining(from)
    ? from
    : offline
    ? Routes.afterAccount(from)
    : Routes.accountDataFrom(from, welcome: true);

// O portão do pacote de treino retoma sozinho depois da conta.
bool _isTraining(String from) =>
    Routes.isRouteFrom(from) &&
    Uri.tryParse(from)?.path.startsWith('/training/') == true;

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

/// O aviso de uma entrada que não deu certo, na Entrada e no e-mail
/// (H-CON-06): o erro fora da lista conhecida diz "Ocorreu um erro
/// inesperado" com "Tentar de novo" ([onRetry], gap 4); o e-mail que já tem
/// conta oferece "Entrar" ([onSignIn]).
void showAccountFailure(
  BuildContext context,
  AccountFailure failure, {
  required VoidCallback onRetry,
  VoidCallback? onSignIn,
}) {
  final l10n = context.l10n;
  final (text, action) = switch (failure) {
    AccountFailure.emailInUse when onSignIn != null => (
      l10n.conEmailInUse,
      SnackBarAction(
        key: AccountKeys.inUseSignIn,
        label: l10n.accountSignIn,
        onPressed: onSignIn,
      ),
    ),
    AccountFailure.unknown => (
      l10n.conUnexpected,
      SnackBarAction(
        key: AccountKeys.failureRetry,
        label: l10n.conRetry,
        onPressed: onRetry,
      ),
    ),
    _ => (accountFailureText(l10n, failure), null),
  };
  showLucenaSnackBar(context, text, action: action);
}
