import 'package:flutter/material.dart';

import '../theme/app_shape.dart';

/// Como uma notação destaca o lance atual.
enum MoveHighlight {
  /// O chip em azul cheio (lições e exercícios).
  filled,

  /// O da análise de partida: fundo secundário com contorno, o texto na cor
  /// de sempre.
  outlined;

  /// O fundo do lance na análise de partida ([outlined]): o selecionado com
  /// o fundo secundário e o contorno; os outros sem nada (a borda
  /// transparente mantém a medida).
  static BoxDecoration outlinedDecoration(
    ColorScheme colors, {
    required bool selected,
  }) => BoxDecoration(
    color: selected ? colors.secondaryContainer : Colors.transparent,
    borderRadius: BorderRadius.circular(AppShape.small),
    border: Border.all(color: selected ? colors.outline : Colors.transparent),
  );
}
