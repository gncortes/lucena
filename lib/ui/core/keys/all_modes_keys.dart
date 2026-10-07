import 'package:flutter/widgets.dart';

/// A tela com todos os modos do app.
abstract final class AllModesKeys {
  static const screen = Key('allModes.screen');

  /// O cartão de um modo, pelo nome dele (`journey`, `blind`...).
  static Key item(String mode) => Key('allModes.item.$mode');
}
