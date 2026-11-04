import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Quanto a abertura espera o Firebase. Ele roda antes do primeiro quadro: se
/// a rede ou os serviços do Google travam, o app não pode ficar preso no fundo
/// liso (Gap 5 da abertura). Passado o limite, o app sobe sem Firebase, como
/// no build sem a configuração nativa.
const firebaseStartTimeout = Duration(seconds: 4);

/// Liga o Firebase com a configuração nativa do flavor.
///
/// O arquivo de configuração não é versionado: sem ele (CI de PR, forks,
/// F-Droid) o app sobe sem Firebase e as peças que dependem dele ficam
/// desligadas. Devolve se o Firebase está disponível. [initialize] e
/// [timeout] existem para o teste.
Future<bool> startFirebase({
  Future<void> Function()? initialize,
  Duration timeout = firebaseStartTimeout,
}) async {
  try {
    await (initialize?.call() ?? Firebase.initializeApp()).timeout(timeout);
    return true;
  } on Object catch (error) {
    debugPrint('Firebase desligado: $error');
    return false;
  }
}
