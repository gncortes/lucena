import 'package:flutter/material.dart';

import 'app_shape.dart';

/// A folha de baixo do app (T73, D7; canvas 79d4acc): raio 28, alça 32×4 e o
/// ✕ redondo por fora. O desenho mora em `showLucenaSheet`; aqui ficam os
/// valores e o tema.
abstract final class AppSheet {
  /// Raio do topo da folha.
  static const radius = AppShape.extraLarge;

  /// Alça: 32×4 numa faixa de 48 (CompCabecalhoFolha).
  static const handleSize = Size(32, 4);
  static const handleStrip = 48.0;

  /// O fundo escurecido atrás da folha: 32% de preto (padrão do M3).
  static final scrim = Colors.black.withValues(alpha: 0.32);

  static const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
  );
}
