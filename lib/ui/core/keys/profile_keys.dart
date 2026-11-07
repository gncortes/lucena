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

  /// O ícone e a frase do cartão: salvando, salvo agora, última vez.
  static const syncIcon = Key('profile.syncIcon');
  static const syncStatus = Key('profile.syncStatus');

  /// O aviso da conta suspensa pelo admin, no lugar do cartão da
  /// sincronização (H-R5-43).
  static const accountBlocked = Key('profile.accountBlocked');

  static const rowCountry = Key('profile.rowCountry');
  static const rowRegion = Key('profile.rowRegion');
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

  /// O aviso de falha dentro da folha do Lichess.
  static const lichessNotice = Key('profile.lichessNotice');

  /// "Notificações", no segundo grupo: abre a tela dos avisos.
  static const rowNotices = Key('profile.rowNotices');

  /// Os grupos do fim (E1.25): "Remover anúncios"; Privacidade, feedback e
  /// avaliar.
}
