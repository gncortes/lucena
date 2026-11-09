// T87 · A aba Seu jogo contra o Emulator Suite do servidor (projeto
// demo-lucena, semente tools/t87_semente.js): login de teste, Firestore e
// Functions de verdade, num app Firebase à parte (o padrão do app fica como
// está). Rodar por `REAL=1 bash tools/t87_seu_jogo_patrol.sh`, que passa a
// senha da semente por define, sem mostrar.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/coach/coach_repository.dart';
import 'package:lucena/data/services/firebase/coach_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/ui/core/keys/coach_your_game_keys.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/your_game_robot.dart';
import 'robots/training_capture_robot.dart';

const _host = '10.0.2.2';
const _email = 'treinador@teste.lucena';
const _password = String.fromEnvironment('T87_SENHA');
// Prints para o qa-telas só com o coletor no ar (ver o _prints_test).
const _withShot = bool.hasEnvironment('E2E_CAPTURE_URL');

const _demo = FirebaseOptions(
  apiKey: 'demo-key',
  appId: '1:1:android:1',
  messagingSenderId: '1',
  projectId: 'demo-lucena',
);

Future<CoachRepository> _server() async {
  // O Firestore do pacote exige o app padrão de pé, mesmo usando outro; no
  // modo E2E ninguém o cria. Fica com as opções de demo, sem projeto real.
  if (!Firebase.apps.any((a) => a.name == defaultFirebaseAppName)) {
    await Firebase.initializeApp(options: _demo);
  }
  final app =
      Firebase.apps.where((a) => a.name == 't87').firstOrNull ??
      await Firebase.initializeApp(name: 't87', options: _demo);
  final auth = FirebaseAuth.instanceFor(app: app);
  final db = FirebaseFirestore.instanceFor(app: app);
  final functions = FirebaseFunctions.instanceFor(
    app: app,
    region: 'southamerica-east1',
  );
  try {
    await auth.useAuthEmulator(_host, 9099);
    db.useFirestoreEmulator(_host, 8085);
    functions.useFunctionsEmulator(_host, 5001);
  } on Object {
    // Já apontado no caso anterior do arquivo.
  }
  if (auth.currentUser == null) {
    await auth.signInWithEmailAndPassword(email: _email, password: _password);
  }
  return CloudCoachRepository(
    FirebaseCoachService(firestore: db, functions: functions),
    PreferencesService(),
    uids: auth.authStateChanges().map((u) => u?.uid),
    currentUid: () => auth.currentUser?.uid,
  );
}

void main() {
  patrolTest('servidor real: as 3 prontas, sem texto cortado', ($) async {
    expect(_password, isNotEmpty, reason: 'rodar pelo t87_seu_jogo_patrol.sh');
    final app = AppRobot($);
    final yourGame = YourGameRobot($);
    await app.open(systemLocale: const Locale('pt'), coach: await _server());
    await yourGame.open();
    // 3 prontas; a na fila, a com erro e a nova ficam fora.
    await $(YourGameKeys.few).waitUntilVisible();
    yourGame.expectBase('3 partidas do Lichess');
    if (_withShot) {
      await TrainingCaptureRobot.semFaixaDoTeste($);
      await TrainingCaptureRobot($)
          .shot('07-real-aba', ready: YourGameKeys.tab);
    }
    // Com 3 partidas a aba cabe numa tela: a 07 já mostra o fim.
    await yourGame.scrollCheckingText(app);
    await yourGame.pickTimeControl('blitz');
    yourGame.expectBase('3 partidas do Lichess');
  });
}
