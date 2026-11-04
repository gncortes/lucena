import 'package:flutter/widgets.dart';

/// A atualização obrigatória e a recomendada (E1.32).
abstract final class UpdateKeys {
  static const requiredScreen = Key('update.required.screen');
  static const requiredAction = Key('update.required.action');
  static const recommendedScreen = Key('update.recommended.screen');
  static const recommendedAction = Key('update.recommended.action');
  static const recommendedLater = Key('update.recommended.later');
  static const requiredOfflineScreen = Key('update.required.offline');
  static const requiredRetry = Key('update.required.retry');
  static const recommendedOfflineScreen = Key('update.recommended.offline');
  static const recommendedRetry = Key('update.recommended.retry');
  static const restart = Key('update.restart');
  static const readyNotice = Key('update.readyNotice');
}
