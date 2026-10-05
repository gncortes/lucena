import 'package:flutter/material.dart';

import '../../../domain/models/app_accent.dart';

abstract final class AppTheme {
  // De fábrica: claro em azul-marinho, escuro em verde. O laranja do mascote
  // só vira cor do app se o jogador escolher.
  static ThemeData get light => of(Brightness.light);
  static ThemeData get dark => of(Brightness.dark);

  static final _themes = <(Brightness, AppAccent), ThemeData>{};

  /// O tema de [brightness] na cor [accent]. Sem cor escolhida, a de fábrica
  /// desse tema.
  static ThemeData of(Brightness brightness, {AppAccent? accent}) {
    final dark = brightness == Brightness.dark;
    final color = accent ?? AppAccent.standard(dark: dark);
    return _themes[(brightness, color)] ??= dark
        ? _buildDark(_darkPalettes[color]!)
        : _buildLight(_lightPalettes[color]!);
  }

  // Cada cor tem dois tons: um para o tema claro e um para o escuro, com o
  // fundo puxado de leve para a mesma família.
  static const _lightPalettes = {
    AppAccent.blue: _LightPalette(
      seed: Color(0xFF1B3A6B),
      primary: Color(0xFF24508F),
      primaryContainer: Color(0xFFD6E4FB),
      onPrimaryContainer: Color(0xFF0D2B57),
      onSecondaryContainer: Color(0xFF243B63),
      background: Color(0xFFF5F7F4),
    ),
    AppAccent.green: _LightPalette(
      seed: Color(0xFF1B6B45),
      primary: Color(0xFF1F7A4F),
      primaryContainer: Color(0xFFD2F0DF),
      onPrimaryContainer: Color(0xFF0C3F27),
      onSecondaryContainer: Color(0xFF24503A),
      background: Color(0xFFF4F7F3),
    ),
    AppAccent.purple: _LightPalette(
      seed: Color(0xFF4A2E8F),
      primary: Color(0xFF6243B5),
      primaryContainer: Color(0xFFE6DEFA),
      onPrimaryContainer: Color(0xFF2A1560),
      onSecondaryContainer: Color(0xFF3C2E66),
      background: Color(0xFFF7F5F9),
    ),
    AppAccent.pink: _LightPalette(
      seed: Color(0xFF8F2460),
      primary: Color(0xFFB02E76),
      primaryContainer: Color(0xFFFBDAEA),
      onPrimaryContainer: Color(0xFF570B35),
      onSecondaryContainer: Color(0xFF632947),
      background: Color(0xFFF9F5F7),
    ),
    AppAccent.orange: _LightPalette(
      seed: Color(0xFF9A4A10),
      primary: Color(0xFFB85410),
      primaryContainer: Color(0xFFFCE1CB),
      onPrimaryContainer: Color(0xFF512305),
      onSecondaryContainer: Color(0xFF5E3B24),
      background: Color(0xFFF9F6F2),
    ),
    AppAccent.teal: _LightPalette(
      seed: Color(0xFF0F5A63),
      primary: Color(0xFF12717C),
      primaryContainer: Color(0xFFCFEEF1),
      onPrimaryContainer: Color(0xFF05383E),
      onSecondaryContainer: Color(0xFF214A4F),
      background: Color(0xFFF3F7F7),
    ),
  };

  static const _darkPalettes = {
    AppAccent.blue: _DarkPalette(
      seed: Color(0xFF3D7FD9),
      background: Color(0xFF131C29),
      sheet: Color(0xFF1B2738),
    ),
    AppAccent.green: _DarkPalette(
      seed: Color(0xFF2E9E6B),
      background: Color(0xFF14211B),
      sheet: Color(0xFF1D2D25),
    ),
    AppAccent.purple: _DarkPalette(
      seed: Color(0xFF8566D6),
      background: Color(0xFF1B1728),
      sheet: Color(0xFF262138),
    ),
    AppAccent.pink: _DarkPalette(
      seed: Color(0xFFD45A92),
      background: Color(0xFF25161D),
      sheet: Color(0xFF33202A),
    ),
    AppAccent.orange: _DarkPalette(
      seed: Color(0xFFD9772B),
      background: Color(0xFF241B13),
      sheet: Color(0xFF31251B),
    ),
    AppAccent.teal: _DarkPalette(
      seed: Color(0xFF2B9AA3),
      background: Color(0xFF122123),
      sheet: Color(0xFF1A2E31),
    ),
  };

  // O esquema gerado deixa a cor principal quase preta e o destaque escuro
  // com texto claro: aqui, uma cor mais viva e destaques claros.
  static ThemeData _buildLight(_LightPalette palette) => _build(
    Brightness.light,
    seed: palette.seed,
    background: palette.background,
    sheet: const Color(0xFFFFFFFF),
    adjust: (scheme) => scheme.copyWith(
      primary: palette.primary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
    ),
  );

  static ThemeData _buildDark(_DarkPalette palette) => _build(
    Brightness.dark,
    seed: palette.seed,
    background: palette.background,
    sheet: palette.sheet,
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

class _LightPalette {
  const _LightPalette({
    required this.seed,
    required this.primary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.onSecondaryContainer,
    required this.background,
  });

  final Color seed;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color onSecondaryContainer;
  final Color background;
}

class _DarkPalette {
  const _DarkPalette({
    required this.seed,
    required this.background,
    required this.sheet,
  });

  final Color seed;
  final Color background;
  final Color sheet;
}
