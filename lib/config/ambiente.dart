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

/// O bloco intersticial do AdMob (E1.22). O id de verdade vem do CI
/// (`--dart-define=ADMOB_INTERSTITIAL_ID`, `vars.ADMOB_INTERSTITIAL_ID` no
/// release.yml); o App ID vai no manifest pelo `build.gradle.kts`.
///
/// - `dev`: sempre o bloco de teste do Google (QA e Patrol nunca pedem
///   anúncio de verdade);
/// - `prod`: o id do CI; sem ele, nulo, e o build fica sem anúncio (nunca o
///   de teste em produção).
abstract final class AdMob {
  /// Os ids de teste oficiais do Google (developers.google.com/admob).
  static const testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static const _define = String.fromEnvironment('ADMOB_INTERSTITIAL_ID');

  /// O bloco que o build usa, ou nulo (sem anúncio). [define] e [ambiente]
  /// existem para o teste.
  static String? interstitialId({String define = _define, Ambiente? ambiente}) {
    if (!(ambiente ?? Ambiente.atual()).isProd) return testInterstitialId;
    final id = define.trim();
    return id.isEmpty || id == testInterstitialId ? null : id;
  }
}

/// O Firebase Emulator Suite para o QA (`--dart-define=FIREBASE_EMULADOR=true`),
/// desligado por padrão e nunca no `prod`. O emulador Android enxerga o
/// computador em [host]. As portas são as do `firebase.json`. O app usa só o
/// Auth e o Firestore; as Functions do emulador ([functionsPort]) reagem ao
/// Firestore dele, sem chamada do app.
abstract final class FirebaseEmulador {
  static const host = '10.0.2.2';
  static const authPort = 9099;
  static const firestorePort = 8085;
  static const functionsPort = 5001;

  /// Se o build aponta para o emulador. [define] e [ambiente] existem para o
  /// teste.
  static bool ligado({
    bool define = const bool.fromEnvironment('FIREBASE_EMULADOR'),
    Ambiente? ambiente,
  }) => define && !(ambiente ?? Ambiente.atual()).isProd;
}
