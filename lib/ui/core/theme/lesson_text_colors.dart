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

  /// O lance com "?" na lista (canvas `T70-etapa1-estados`, Gabriel
  /// 14/10/2026).
  static const mistake = Color(0xFF9A4A00);

  /// O lance com "??" na lista (erro grave; canvas `CompNotacao`, `grave`).
  static const blunder = Color(0xFFB3261E);

  /// O lance com "!" na lista.
  static const goodMove = Color(0xFF3B6E1C);
}
