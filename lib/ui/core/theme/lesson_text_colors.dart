import 'package:flutter/material.dart';

/// Cores de texto próprias da lição V2 (LICOES-V2 §2), derivadas dos papéis do
/// [ColorScheme]: nada de hex solto no widget.
abstract final class LessonTextColors {
  /// A casa citada no texto (variante A do canvas, ≈#4E76B0 no claro): um tom
  /// mais claro que o `primary` do lance, para a casa não competir com ele.
  static Color square(ColorScheme colors) =>
      colors.brightness == Brightness.dark
      ? Color.lerp(colors.primary, colors.onPrimaryContainer, .5)!
      : Color.lerp(colors.primary, colors.surface, .20)!;

  /// Fundo do lance que está no tabuleiro: `primary` translúcido.
  static Color activeMoveBackground(ColorScheme colors) => colors.primary
      .withValues(alpha: colors.brightness == Brightness.dark ? .22 : .14);
}
