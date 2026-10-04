import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFFFF7A1A);

  static final light = _build(
    Brightness.light,
    background: const Color(0xFFF5F7F4),
    sheet: const Color(0xFFFFFFFF),
  );
  static final dark = _build(
    Brightness.dark,
    background: const Color(0xFF14211B),
    sheet: const Color(0xFF1D2D25),
  );

  static ThemeData _build(
    Brightness brightness, {
    required Color background,
    required Color sheet,
  }) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: brightness,
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
