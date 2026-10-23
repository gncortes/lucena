import 'package:flutter/material.dart';

import '../../../domain/models/app_accent.dart';
import 'app_button.dart';
import 'app_colors.dart';
import 'app_shape.dart';
import 'app_sheet.dart';
import 'app_spacing.dart';
import 'app_tokens.dart';

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
      primary: Color(0xFF1B6E47),
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
      secondaryContainer: Color(0xFFF5D5E3),
      onSecondaryContainer: Color(0xFF632947),
      background: Color(0xFFF9F5F7),
    ),
    AppAccent.orange: _LightPalette(
      seed: Color(0xFF9A4A10),
      primary: Color(0xFFA14A0E),
      primaryContainer: Color(0xFFFCE1CB),
      onPrimaryContainer: Color(0xFF512305),
      secondaryContainer: Color(0xFFF5DCC9),
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
    sheet: _white,
    adjust: (scheme) => scheme.copyWith(
      primary: palette.primary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      // O gerado no rosa e no laranja sai saturado demais atrás do texto.
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
      // Fundos do canvas: `surface` na cor do fundo e painéis/cartões brancos,
      // sem o lilás que a semente gera.
      surface: palette.background,
      surfaceContainerLow: _white,
      // O terciário é o dourado do canvas (D26), igual em toda cor do app.
      tertiary: _tertiary,
      tertiaryContainer: _tertiaryContainer,
      onTertiaryContainer: _onTertiaryContainer,
    ),
  );

  static const _white = Color(0xFFFFFFFF);
  static const _tertiary = Color(0xFF7A5900);
  static const _tertiaryContainer = Color(0xFFFFE2A6);
  static const _onTertiaryContainer = Color(0xFF3B2A00);

  // No escuro, a cor principal viva da semente, mas os destaques (fundo de
  // ficha, de selo e do segmentado) num tom escuro da mesma família com texto
  // claro: o esquema gerado põe a própria semente, berrante, atrás do texto.
  // Cartão e painel um degrau acima do fundo, nunca brancos.
  static ThemeData _buildDark(_DarkPalette palette) => _build(
    Brightness.dark,
    seed: palette.seed,
    background: palette.background,
    sheet: palette.sheet,
    adjust: (scheme) {
      final tonal = ColorScheme.fromSeed(
        seedColor: palette.seed,
        brightness: Brightness.dark,
      );
      Color lift(double amount) =>
          Color.lerp(palette.background, _white, amount)!;
      return scheme.copyWith(
        primaryContainer: tonal.primaryContainer,
        onPrimaryContainer: tonal.onPrimaryContainer,
        secondaryContainer: tonal.secondaryContainer,
        onSecondaryContainer: tonal.onSecondaryContainer,
        surface: palette.background,
        surfaceContainerLowest: Color.lerp(palette.background, _black, 0.3),
        surfaceContainerLow: palette.sheet,
        surfaceContainer: lift(0.09),
        surfaceContainerHigh: lift(0.13),
        surfaceContainerHighest: lift(0.17),
        // O mesmo dourado do claro (D26), no tom do escuro.
        tertiary: _tertiaryDark,
        onTertiary: _onTertiaryDark,
        tertiaryContainer: _tertiaryContainerDark,
        onTertiaryContainer: _tertiaryContainer,
      );
    },
  );

  static const _black = Color(0xFF000000);
  static const _tertiaryDark = Color(0xFFF2C14E);
  static const _onTertiaryDark = Color(0xFF3F2E00);
  static const _tertiaryContainerDark = Color(0xFF5A4300);

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
    final colors = adjust == null ? scheme : adjust(scheme);
    // Altura mínima de todo botão (D19): 48; o rodapé e as folhas pedem 52.
    const buttonSize = Size(64, kButtonHeightCompact);
    return ThemeData(
      colorScheme: colors,
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
        shape: AppSheet.shape,
        modalBarrierColor: AppSheet.scrim,
        dragHandleSize: AppSheet.handleSize,
      ),
      // Cartão sem sombra, com o raio grande dos tokens (D24): branco no
      // claro, um degrau acima do fundo no escuro.
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppShape.large)),
        ),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(buttonSize)),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(buttonSize)),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(buttonSize)),
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(minimumSize: WidgetStatePropertyAll(buttonSize)),
      ),
      // Chip de escolha e de filtro com o check e raio 8 (D22). O de
      // informação (`InfoChip`) tira a borda no próprio widget.
      chipTheme: ChipThemeData(
        showCheckmark: true,
        // A ficha não escolhida é transparente nos dois temas (CompChip): pega
        // o tom do que está embaixo, branca na folha e no painel e do fundo na
        // tela.
        backgroundColor: Colors.transparent,
        // Altura visual de 32 (CompChip): o Flutter soma o preenchimento
        // vertical ao mínimo de 32, então os dois ficam sem vertical.
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppShape.small)),
        ),
      ),
      // Aviso flutuante escuro, sem botão de fechar (D29).
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        showCloseIcon: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppShape.small)),
        ),
      ),
      // Segmentado de 40, selecionado no secundário (D30). O check sai em cada
      // `SegmentedButton` (`showSelectedIcon: false`): o tema não o desliga.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.secondaryContainer
                : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? colors.onSecondaryContainer
                : colors.onSurface,
          ),
        ),
      ),
      // Campo contornado de raio 12, rótulo sempre em cima (D31).
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppShape.medium)),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      // Divisor fino de 1, colado no conteúdo (D32).
      dividerTheme: DividerThemeData(
        thickness: 1,
        space: 1,
        color: colors.outlineVariant,
      ),
      extensions: const [AppTokens.standard, AppColors.standard],
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
    this.secondaryContainer,
  });

  final Color seed;
  final Color primary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color onSecondaryContainer;
  final Color background;
  final Color? secondaryContainer;
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
