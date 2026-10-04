import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFFFF7A1A);

  static final light = _build(Brightness.light, const Color(0xFFF5F7F4));
  static final dark = _build(Brightness.dark, const Color(0xFF14211B));

  static ThemeData _build(Brightness brightness, Color background) {
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
    );
  }
}
