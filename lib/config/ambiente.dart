import 'package:flutter/services.dart' show appFlavor;

/// Ambiente do build. Vem do `--flavor dev|prod`, que o Flutter já expõe em
/// [appFlavor]: não há `--dart-define` a mais. Este é o único lugar que lê o flavor.
///
/// Sem flavor (testes unitários, `flutter run` sem `--flavor`) vale [prod].
enum Ambiente {
  dev,
  prod;

  static Ambiente get atual => deFlavor(appFlavor);

  /// Converte o nome do flavor; nulo ou desconhecido cai em [prod], o mais restritivo.
  static Ambiente deFlavor(String? flavor) =>
      flavor == 'dev' ? Ambiente.dev : Ambiente.prod;

  bool get ehDev => this == Ambiente.dev;
}
