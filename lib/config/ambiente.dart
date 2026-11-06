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
