import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';

/// "Liberar espaço" do erro de falta de espaço: abre o armazenamento do
/// celular nos ajustes do sistema. Nulo fora do Android (o botão some).
VoidCallback? freeSpaceAction(BuildContext context) {
  if (Theme.of(context).platform != TargetPlatform.android) return null;
  return () async {
    try {
      await const AndroidIntent(
        action: 'android.settings.INTERNAL_STORAGE_SETTINGS',
      ).launch();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
  };
}
