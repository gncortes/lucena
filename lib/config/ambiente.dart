// Dart puro (o domínio usa o [Ambiente.siteHost]): o flavor vem do mesmo
// define que o `appFlavor` do Flutter lê (services/flavor.dart).
const String _flavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');

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
  static Ambiente atual({String? flavor = _flavor}) =>
      flavor == 'prod' ? prod : dev;

  bool get isProd => this == prod;

  /// O site do ambiente (sem `https://`): os links que o app gera, os App
  /// Links e as páginas do site (Sobre, privacidade, termos). A troca é aqui
  /// e no `appLinkHost` do `android/app/build.gradle.kts`.
  String get siteHost => switch (this) {
    dev => 'dev.playlucenachess.com',
    prod => 'playlucenachess.com',
  };
}

/// O Firebase Emulator Suite para o QA (`--dart-define=FIREBASE_EMULADOR=true`),
/// desligado por padrão e nunca no `prod`. O emulador Android enxerga o
/// computador em [host]. As portas são as do `firebase.json`. O app usa o
/// Auth, o Firestore e as Functions chamáveis do Treinador ([functionsPort]);
/// as outras Functions do emulador reagem ao Firestore dele.
abstract final class FirebaseEmulador {
  static const host = '10.0.2.2';
  // Outra porta só quando duas frentes sobem o Emulator Suite ao mesmo tempo
  // (`--dart-define=FIREBASE_EMULADOR_AUTH=9199`, e assim por diante).
  static const authPort = int.fromEnvironment(
    'FIREBASE_EMULADOR_AUTH',
    defaultValue: 9099,
  );
  static const firestorePort = int.fromEnvironment(
    'FIREBASE_EMULADOR_FIRESTORE',
    defaultValue: 8085,
  );
  static const functionsPort = int.fromEnvironment(
    'FIREBASE_EMULADOR_FUNCTIONS',
    defaultValue: 5001,
  );

  /// Se o build aponta para o emulador. [define] e [ambiente] existem para o
  /// teste.
  static bool ligado({
    bool define = const bool.fromEnvironment('FIREBASE_EMULADOR'),
    Ambiente? ambiente,
  }) => define && !(ambiente ?? Ambiente.atual()).isProd;
}
