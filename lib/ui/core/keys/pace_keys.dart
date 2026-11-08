import 'package:flutter/widgets.dart';

/// O painel de escolha do ritmo.
abstract final class PaceKeys {
  static const sheet = Key('pace.sheet');
  static Key option(String code) => Key('pace.option.$code');
  static const noClock = Key('pace.noClock');

  /// O selo "Recomendado" ao lado da categoria do ritmo padrão.
  static const recommended = Key('pace.recommended');
  static const confirm = Key('pace.confirm');
}
