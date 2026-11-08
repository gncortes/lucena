import 'package:flutter/widgets.dart';

/// O toque no push do presente (H-R5-63): abrindo, falha e entrar na conta.
abstract final class GiftOpeningKeys {
  /// "Abrindo o seu presente…" (`PropV2PresenteAbrindo`).
  static const opening = Key('giftOpening.opening');

  /// "Não foi possível abrir o presente agora." e "Tentar novamente".
  static const failed = Key('giftOpening.failed');
  static const retry = Key('giftOpening.retry');

  /// Entrar para ver o presente (`PropV2PresenteSemConta`).
  static const signIn = Key('giftOpening.signIn');
  static const signInBack = Key('giftOpening.signIn.back');
  static const signInText = Key('giftOpening.signIn.text');
  static const google = Key('giftOpening.signIn.google');
  static const email = Key('giftOpening.signIn.email');
}
