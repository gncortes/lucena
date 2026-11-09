import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../config/ambiente.dart';
import 'treinador_service.dart';

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
    await (initialize?.call() ?? initializeFirebaseApp()).timeout(timeout);
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
  // O Treinador (T87) chama as Functions da região do servidor.
  FirebaseFunctions.instanceFor(
    region: FirebaseTreinadorService.regiao,
  ).useFunctionsEmulator(FirebaseEmulador.host, FirebaseEmulador.functionsPort);
}

/// O projeto do Emulator Suite quando o checkout não tem o arquivo de
/// configuração do flavor (worktree de QA): o emulador aceita qualquer chave,
/// então nada aqui é segredo nem aponta para o projeto de verdade.
const emulatorFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaEmuladorDoLucenaSemSegredoNenhum000',
  appId: '1:0:android:0',
  messagingSenderId: '0',
  projectId: 'lucena-dev-gnc',
  storageBucket: 'lucena-dev-gnc.appspot.com',
);

/// Abre o Firebase pelo arquivo do flavor; só com [FirebaseEmulador.ligado]
/// e sem o arquivo, abre com [emulatorFirebaseOptions].
Future<FirebaseApp> initializeFirebaseApp({bool? emulador}) async {
  try {
    return await Firebase.initializeApp();
  } on Object {
    if (!(emulador ?? FirebaseEmulador.ligado())) rethrow;
    return Firebase.initializeApp(options: emulatorFirebaseOptions);
  }
}

/// O atestado do App Check por ambiente: Play Integrity no app da Play; no
/// `dev` (local, Patrol, QA pelo App Distribution), o provedor de depuração,
/// cujo token aparece no logcat e é cadastrado no console
/// (`docs/tasks/T85-app-check-passos.md`). Nenhum token vai no código.
AndroidAppCheckProvider appCheckProvider(Ambiente ambiente) => ambiente.isProd
    ? const AndroidPlayIntegrityProvider()
    : const AndroidDebugProvider();
