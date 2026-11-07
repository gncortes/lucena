import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../config/ambiente.dart';

/// Quanto a abertura espera o Firebase. Ele roda antes do primeiro quadro: se
/// a rede ou os serviços do Google travam, o app não pode ficar preso no fundo
/// liso (Gap 5 da abertura). Passado o limite, o app sobe sem Firebase, como
/// no build sem a configuração nativa.
const firebaseStartTimeout = Duration(seconds: 4);

/// Liga o Firebase com a configuração nativa do flavor e, em seguida, o App
/// Check ([appCheckProvider]).
///
/// O arquivo de configuração não é versionado: sem ele (CI de PR, forks,
/// F-Droid) o app sobe sem Firebase e as peças que dependem dele ficam
/// desligadas. Devolve se o Firebase está disponível. O App Check que falha
/// não desliga o Firebase: enquanto o console não exige o atestado, tudo
/// segue igual. Com [FirebaseEmulador.ligado], Auth e Firestore vão para o
/// Emulator Suite. [initialize], [appCheck], [emulador], [useEmulator] e
/// [timeout] existem para o teste.
Future<bool> startFirebase({
  Future<void> Function()? initialize,
  Future<void> Function(AndroidAppCheckProvider provider)? appCheck,
  Ambiente? ambiente,
  bool? emulador,
  Future<void> Function()? useEmulator,
  Duration timeout = firebaseStartTimeout,
}) async {
  try {
    await (initialize?.call() ?? Firebase.initializeApp()).timeout(timeout);
  } on Object catch (error) {
    debugPrint('Firebase desligado: $error');
    return false;
  }
  if (emulador ?? FirebaseEmulador.ligado()) {
    try {
      await (useEmulator?.call() ?? useFirebaseEmulator()).timeout(timeout);
    } on Object catch (error) {
      // Sem o emulador o QA não pode cair no projeto de verdade.
      debugPrint('Emulador do Firebase fora: $error');
      return false;
    }
  }
  final provider = appCheckProvider(ambiente ?? Ambiente.atual());
  try {
    await (appCheck?.call(provider) ??
            FirebaseAppCheck.instance.activate(providerAndroid: provider))
        .timeout(timeout);
  } on Object catch (error) {
    debugPrint('App Check desligado: $error');
  }
  return true;
}

/// Aponta o Auth e o Firestore para o Emulator Suite do computador.
Future<void> useFirebaseEmulator() async {
  await FirebaseAuth.instance.useAuthEmulator(
    FirebaseEmulador.host,
    FirebaseEmulador.authPort,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    FirebaseEmulador.host,
    FirebaseEmulador.firestorePort,
  );
}

/// O atestado do App Check por ambiente: Play Integrity no app da Play; no
/// `dev` (local, Patrol, QA pelo App Distribution), o provedor de depuração,
/// cujo token aparece no logcat e é cadastrado no console
/// (`docs/tasks/T85-app-check-passos.md`). Nenhum token vai no código.
AndroidAppCheckProvider appCheckProvider(Ambiente ambiente) => ambiente.isProd
    ? const AndroidPlayIntegrityProvider()
    : const AndroidDebugProvider();
