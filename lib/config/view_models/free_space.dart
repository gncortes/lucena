import 'package:android_intent_plus/android_intent.dart';

import '../../data/repositories/diagnostics/failure_report_repository.dart';

/// Abre o armazenamento do celular nos ajustes do Android. Falha vira
/// registro, nunca erro na tela.
Future<void> openStorageSettings() async {
  try {
    await const AndroidIntent(
      action: 'android.settings.INTERNAL_STORAGE_SETTINGS',
    ).launch();
  } on Object catch (error, stack) {
    reportHandledError(error, stack);
  }
}
