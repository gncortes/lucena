import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Claro em azul-marinho, escuro em verde. O laranja fica só no mascote.
  static final light = _build(
    Brightness.light,
    seed: const Color(0xFF1B3A6B),
    background: const Color(0xFFF5F7F4),
    sheet: const Color(0xFFFFFFFF),
  );
  static final dark = _build(
    Brightness.dark,
    seed: const Color(0xFF2E9E6B),
    background: const Color(0xFF14211B),
    sheet: const Color(0xFF1D2D25),
  );

  static ThemeData _build(
    Brightness brightness, {
    required Color seed,
    required Color background,
    required Color sheet,
  }) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        // Mantém a cor principal perto da cor escolhida, sem desbotar.
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ),
      scaffoldBackgroundColor: background,
      // A barra superior tem o mesmo fundo da tela, sem mudar de cor ao rolar.
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      // Painéis que sobem de baixo: um tom acima do fundo, na mesma família.
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheet,
        modalBackgroundColor: sheet,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
