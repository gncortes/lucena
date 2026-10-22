import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Liga o Firebase com a configuração nativa (`google-services.json`).
///
/// O arquivo não é versionado: sem ele (CI de PR, forks, F-Droid) o app sobe
/// sem Firebase e as peças que dependem dele ficam desligadas. Devolve se o
/// Firebase está disponível.
Future<bool> startFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } on Object catch (error) {
    debugPrint('Firebase desligado: $error');
    return false;
  }
}
