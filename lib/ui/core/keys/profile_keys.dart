import 'package:flutter/widgets.dart';

abstract final class ProfileKeys {
  static const screen = Key('profile.screen');

  /// Avatar, nome e a linha da conta; o lápis abre "Seus dados".
  static const header = Key('profile.header');
  static const headerName = Key('profile.header.name');
  static const editData = Key('profile.editData');

  /// Sem conta: "Seu progresso está só neste celular".
  static const localCard = Key('profile.localCard');
  static const createAccount = Key('profile.createAccount');

  /// Com conta: "Tudo guardado na conta".
  static const syncCard = Key('profile.syncCard');

  static const rowCountry = Key('profile.rowCountry');
  static const rowLanguage = Key('profile.rowLanguage');

  /// A linha "Seu objetivo", que abre a folha do objetivo.
  static const rowGoal = Key('profile.rowGoal');

  /// A linha "Seu nível", que abre a tela do nível (E1.12).
  static const rowLevel = Key('profile.rowLevel');
  static const rowLichess = Key('profile.rowLichess');

  static const signOut = Key('profile.signOut');
  static const delete = Key('profile.delete');

  static const lichessSheet = Key('profile.lichessSheet');
  static const lichessRefresh = Key('profile.lichessRefresh');
  static const lichessDisconnect = Key('profile.lichessDisconnect');

  /// O histórico do rating de finais.
  static const ratingCard = Key('profile.rating');
}
