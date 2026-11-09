import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucena/config/ambiente.dart';
import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/push/push_repository.dart';
import 'package:lucena/data/services/firebase/firebase_bootstrap.dart';

import 'fakes/fake_push_service.dart';

bool? _firebase;

/// Liga o Firebase uma vez por processo, apontado para o Emulator Suite do
/// computador (Auth, Firestore e Functions em [FirebaseEmulador.host]). O
/// Auth e o Firestore só aceitam o emulador antes do primeiro uso: os
/// cenários seguintes reaproveitam a ligação.
Future<void> startEmulatorFirebase() async {
  if (!FirebaseEmulador.ligado()) {
    throw StateError(
      'Rode com --dart-define=FIREBASE_EMULADOR=true (e o emulador ligado)',
    );
  }
  _firebase ??= await startFirebase(emulador: true);
  if (_firebase != true) {
    throw StateError(
      'Firebase fora: falta o google-services.json do flavor dev ou o '
      'Emulator Suite não respondeu em ${FirebaseEmulador.host}',
    );
  }
}

/// O app como na Play, com a conta, os cursos dados, a sincronização e as
/// opiniões de verdade, só que no emulador. O toque no push vem de [push]:
/// o FCM não é emulado e o cenário entrega o mesmo `data` que a Function
/// manda. Começa sem conta (a sessão do cenário anterior sai).
///
/// Sem [push], o push é o de verdade: o FCM do projeto do flavor dev entrega
/// o que as Functions do emulador mandam (jornada 7, push real).
///
/// [keepAccount]: reabrir depois de fechar à força, com a sessão guardada.
///
/// O Analytics fica desligado pelo `E2E=true` (E1.03 §10).
Future<Dependencies> emulatorDependencies({
  PushRepository? push,
  bool keepAccount = false,
}) async {
  await startEmulatorFirebase();
  if (!keepAccount) await FirebaseAuth.instance.signOut();
  return Dependencies.normal(
    version: await Dependencies.installedVersion(),
    firebase: true,
    trainingInstallSeed: await Dependencies.trainingInstallSeed(),
    push: push,
    pushService: push == null ? null : FakePushService(),
  );
}
