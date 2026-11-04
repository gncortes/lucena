import 'package:flutter/widgets.dart';

abstract final class PrivacyKeys {
  static const screen = Key('privacy.screen');

  /// O cartão "Seus dados pela LGPD".
  static const lgpdCard = Key('privacy.lgpdCard');

  /// "Anúncios sem personalização": linha só de leitura.
  static const ads = Key('privacy.ads');
  static const notifications = Key('privacy.notifications');
  static const microphone = Key('privacy.microphone');
  static const download = Key('privacy.download');
  static const talk = Key('privacy.talk');
  static const terms = Key('privacy.terms');
  static const policy = Key('privacy.policy');
  static const deleteAccount = Key('privacy.deleteAccount');

  /// A folha "Baixar seus dados?" (H-CON-21) e os quadros dela.
  static const downloadSheet = Key('privacy.downloadSheet');
  static const downloadClose = Key('privacy.downloadClose');
  static const downloadStart = Key('privacy.downloadStart');
  static const downloading = Key('privacy.downloading');
  static const downloadReady = Key('privacy.downloadReady');
  static const downloadOpen = Key('privacy.downloadOpen');
  static const downloadError = Key('privacy.downloadError');
  static const downloadRetry = Key('privacy.downloadRetry');

  /// A folha "Remover anúncios".
  static const removeSheet = Key('privacy.removeSheet');
  static const removeBuy = Key('privacy.removeBuy');
  static const removeNo = Key('privacy.removeNo');
  static const removePending = Key('privacy.removePending');
  static const removeError = Key('privacy.removeError');
}
