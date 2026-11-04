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

  /// "Tentar de novo" no aviso de erro inesperado (H-CON-06, gap 4).
  static const failureRetry = Key('account.failureRetry');

  /// "Entrar" no aviso de e-mail que já tem conta (H-CON-06).
  static const inUseSignIn = Key('account.inUseSignIn');

  /// O convite em folha, no fim da 1ª partida.
  static const inviteSheet = Key('account.inviteSheet');
  static const notNow = Key('account.notNow');

  /// O convite em cartão (fim da partida, Seu progresso; H-CON-02/03) e o X.
  static const inviteCard = Key('account.inviteCard');
  static const inviteCardClose = Key('account.inviteCardClose');

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

  /// "Termos e privacidade" (H-CON-08): o aceite logo depois de criar a conta.
  static const acceptScreen = Key('account.accept');
  static const acceptCheck = Key('account.acceptCheck');
  static const acceptTerms = Key('account.acceptTerms');
  static const acceptUsage = Key('account.acceptUsage');
  static const acceptContinue = Key('account.acceptContinue');

  static const editSavedNote = Key('account.editSavedNote');
  static const restoredScreen = Key('account.restored');
  static const restoredContinue = Key('account.restoredContinue');

  static const deleteSheet = Key('account.deleteSheet');
  static const deleteClose = Key('account.deleteClose');
  static const deleteLose = Key('account.deleteLose');
  static const deletePlayWarning = Key('account.deletePlayWarning');
  static const deleteNotice = Key('account.deleteNotice');
  static const deleteConfirm = Key('account.deleteConfirm');
  static const deleteCancel = Key('account.deleteCancel');
}
