import 'package:flutter/widgets.dart';

/// A atualização obrigatória e a recomendada (E1.32).
abstract final class UpdateKeys {
  static const requiredScreen = Key('update.required.screen');
  static const requiredAction = Key('update.required.action');
  static const recommendedScreen = Key('update.recommended.screen');
  static const recommendedAction = Key('update.recommended.action');
  static const recommendedLater = Key('update.recommended.later');
  static const restart = Key('update.restart');
  static const readyNotice = Key('update.readyNotice');
}
