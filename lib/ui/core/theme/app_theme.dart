import 'package:flutter/material.dart';

abstract final class AppTheme {
  // Claro em azul-marinho, escuro em verde. O laranja fica só no mascote.
  static final light = _build(
    Brightness.light,
    seed: const Color(0xFF1B3A6B),
    background: const Color(0xFFF5F7F4),
    sheet: const Color(0xFFFFFFFF),
    // O esquema gerado deixa o azul quase preto e o destaque azul-marinho
    // com texto azul-claro: aqui, um azul mais vivo e destaques claros.
    adjust: (scheme) => scheme.copyWith(
      primary: const Color(0xFF24508F),
      primaryContainer: const Color(0xFFD6E4FB),
      onPrimaryContainer: const Color(0xFF0D2B57),
      onSecondaryContainer: const Color(0xFF243B63),
    ),
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
    ColorScheme Function(ColorScheme scheme)? adjust,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      // Mantém a cor principal perto da cor escolhida, sem desbotar.
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    return ThemeData(
      colorScheme: adjust == null ? scheme : adjust(scheme),
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
      // Uma transição só no app inteiro: a tela nova entra deslizando de leve
      // com fade, numa curva suave.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
