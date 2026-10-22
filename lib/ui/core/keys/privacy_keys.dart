import 'package:flutter/widgets.dart';

abstract final class PrivacyKeys {
  static const screen = Key('privacy.screen');

  /// "O Lucena é grátis" (com anúncios) ou "Sem anúncios" (comprou).
  static const freeCard = Key('privacy.freeCard');
  static const adFreeCard = Key('privacy.adFreeCard');

  static const adChoices = Key('privacy.adChoices');
  static const policy = Key('privacy.policy');
  static const deleteAccount = Key('privacy.deleteAccount');

  /// A folha "Remover anúncios".
  static const removeSheet = Key('privacy.removeSheet');
  static const removeBuy = Key('privacy.removeBuy');
  static const removeNo = Key('privacy.removeNo');
  static const removePending = Key('privacy.removePending');
  static const removeError = Key('privacy.removeError');
}
