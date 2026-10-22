import 'package:flutter/widgets.dart';

/// A conta, opcional (E1.13): convite, entrar, e-mail, "Seus dados",
/// "Bem-vindo de volta" e apagar.
abstract final class AccountKeys {
  /// O convite em tela cheia (vindo de um link) e o "Criar conta ou entrar".
  static const screen = Key('account.screen');
  static const enterScreen = Key('account.enter');
  static const close = Key('account.close');
  static const google = Key('account.google');
  static const email = Key('account.email');
  static const later = Key('account.later');

  /// O convite em folha, no fim da 1ª partida.
  static const inviteSheet = Key('account.inviteSheet');
  static const notNow = Key('account.notNow');

  static const emailScreen = Key('account.emailScreen');
  static const emailField = Key('account.emailField');
  static const passwordField = Key('account.passwordField');
  static const emailSegCreate = Key('account.emailSeg.create');
  static const emailSegSignIn = Key('account.emailSeg.signIn');
  static const emailSubmit = Key('account.emailSubmit');
  static const emailHaveAccount = Key('account.emailHaveAccount');

  static const dataScreen = Key('account.data');
  static const nickname = Key('account.nickname');
  static Key avatar(int index) => Key('account.avatar.$index');
  static const avatarGoogle = Key('account.avatarGoogle');
  static const dataSave = Key('account.dataSave');

  static const restoredScreen = Key('account.restored');
  static const restoredContinue = Key('account.restoredContinue');

  static const deleteDialog = Key('account.deleteDialog');
  static const deleteConfirm = Key('account.deleteConfirm');
  static const deleteCancel = Key('account.deleteCancel');
}
