import 'package:flutter/widgets.dart';

/// A conta, opcional (E1.13, refeita na §2.12): convite, entrada, criar
/// conta, entrar, esqueci a senha, "Seu perfil" com a foto, "Bem-vindo de
/// volta" e apagar.
abstract final class AccountKeys {
  /// O convite em tela cheia (vindo de um link) e o "Criar conta ou entrar".
  static const screen = Key('account.screen');
  static const enterScreen = Key('account.enter');
  static const enterTitle = Key('account.enter.title');
  static const enterText = Key('account.enter.text');
  static const close = Key('account.close');
  static const google = Key('account.google');
  static const email = Key('account.email');
  static const later = Key('account.later');

  /// "Já tem conta? Entrar" e "Não tem conta? Criar conta".
  static const toSignIn = Key('account.toSignIn');
  static const toCreate = Key('account.toCreate');
  static const legal = Key('account.legal');

  /// O convite em folha, no fim da 1ª partida.
  static const inviteSheet = Key('account.inviteSheet');
  static const notNow = Key('account.notNow');

  /// Criar conta e Entrar, com e-mail e senha.
  static const createScreen = Key('account.create');
  static const signInScreen = Key('account.signIn');
  static const emailField = Key('account.emailField');
  static const passwordField = Key('account.passwordField');
  static const passwordEye = Key('account.passwordEye');
  static const emailSubmit = Key('account.emailSubmit');
  static const forgotPassword = Key('account.forgotPassword');

  /// As folhas "Esqueceu a senha?" e "Confira o seu e-mail".
  static const resetSheet = Key('account.resetSheet');
  static const resetEmail = Key('account.resetEmail');
  static const resetSend = Key('account.resetSend');
  static const resetCancel = Key('account.resetCancel');
  static const resetSentSheet = Key('account.resetSent');
  static const resetOpenMail = Key('account.resetOpenMail');
  static const resetOk = Key('account.resetOk');

  /// "Seu perfil" e a folha "Foto do perfil".
  static const dataScreen = Key('account.data');
  static const photo = Key('account.photo');
  static const nickname = Key('account.nickname');
  static const savedBanner = Key('account.savedBanner');
  static const dataSave = Key('account.dataSave');
  static const photoSheet = Key('account.photoSheet');
  static const photoCamera = Key('account.photoCamera');
  static const photoGallery = Key('account.photoGallery');
  static const photoGoogle = Key('account.photoGoogle');
  static Key avatar(int index) => Key('account.avatar.$index');
  static const photoRemove = Key('account.photoRemove');

  static const restoredScreen = Key('account.restored');
  static const restoredContinue = Key('account.restoredContinue');

  static const deleteDialog = Key('account.deleteDialog');
  static const deleteConfirm = Key('account.deleteConfirm');
  static const deleteCancel = Key('account.deleteCancel');
}
