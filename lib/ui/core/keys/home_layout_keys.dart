import 'package:flutter/widgets.dart';

import '../../../domain/models/home_layout.dart';

/// A configuração da tela inicial.
abstract final class HomeLayoutKeys {
  static const screen = Key('homeLayout.screen');
  static const list = Key('homeLayout.list');
  static const restore = Key('homeLayout.restore');

  /// A linha de um caminho, a caixa de marcar e a alça de arrastar.
  static Key item(HomePath path) => Key('homeLayout.item.${path.name}');
  static Key check(HomePath path) => Key('homeLayout.check.${path.name}');
  static Key handle(HomePath path) => Key('homeLayout.handle.${path.name}');
}
