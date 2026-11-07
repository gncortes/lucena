import 'package:flutter/services.dart';

/// O ambiente do build, pelo flavor do Android (`--flavor dev|prod`).
///
/// - `prod`: o app da Play (`com.gncortes.lucena`, projeto lucena-2f4de);
/// - `dev`: local, Patrol e QA (`com.gncortes.lucena.dev`, lucena-dev-gnc).
///
/// Sem flavor (testes, F-Droid), conta como `dev`: nada de produção liga
/// por engano.
enum Ambiente {
  dev,
  prod;

  /// O ambiente deste build. [flavor] existe para o teste.
  static Ambiente atual({String? flavor = appFlavor}) =>
      flavor == 'prod' ? prod : dev;

  bool get isProd => this == prod;
}

/// O Firebase Emulator Suite para o QA (`--dart-define=FIREBASE_EMULADOR=true`),
/// desligado por padrão e nunca no `prod`. O emulador Android enxerga o
/// computador em [host]. O app usa só o Auth e o Firestore; as Functions do
/// emulador ([functionsPort]) reagem ao Firestore dele, sem chamada do app.
abstract final class FirebaseEmulador {
  static const host = '10.0.2.2';
  static const authPort = 9099;
  static const firestorePort = 8080;
  static const functionsPort = 5001;

  /// Se o build aponta para o emulador. [define] e [ambiente] existem para o
  /// teste.
  static bool ligado({
    bool define = const bool.fromEnvironment('FIREBASE_EMULADOR'),
    Ambiente? ambiente,
  }) => define && !(ambiente ?? Ambiente.atual()).isProd;
}
