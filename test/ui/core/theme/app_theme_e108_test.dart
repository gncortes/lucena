import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/ui/core/theme/app_button.dart';
import 'package:lucena/ui/core/theme/app_shape.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';

// Os sub-temas da E1.08 (lote 0): o que toda tela herda sem escrever nada.
void main() {
  for (final accent in AppAccent.values) {
    final theme = AppTheme.of(Brightness.light, accent: accent);

    test('${accent.name}: todo botão tem no mínimo 48 de altura (D19)', () {
      for (final style in [
        theme.filledButtonTheme.style,
        theme.outlinedButtonTheme.style,
        theme.textButtonTheme.style,
        theme.elevatedButtonTheme.style,
      ]) {
        expect(style?.minimumSize?.resolve({})?.height, kButtonHeightCompact);
      }
    });

    test('${accent.name}: cartão branco, sem sombra e sem margem (D24)', () {
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.color, const Color(0xFFFFFFFF));
      expect(theme.cardTheme.margin, EdgeInsets.zero);
    });

    test('${accent.name}: terciário dourado do canvas (D26)', () {
      expect(theme.colorScheme.tertiary, const Color(0xFF7A5900));
      expect(theme.colorScheme.tertiaryContainer, const Color(0xFFFFE2A6));
      expect(theme.colorScheme.onTertiaryContainer, const Color(0xFF3B2A00));
    });
  }

  final theme = AppTheme.light;

  test('chip com check e raio 8 (D22)', () {
    expect(theme.chipTheme.showCheckmark, isTrue);
    expect(
      theme.chipTheme.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppShape.small)),
      ),
    );
  });

  test('aviso flutuante no inverso da superfície (D29)', () {
    final snack = theme.snackBarTheme;
    expect(snack.behavior, SnackBarBehavior.floating);
    expect(snack.backgroundColor, theme.colorScheme.inverseSurface);
    expect(snack.insetPadding, const EdgeInsets.all(16));
    expect(snack.showCloseIcon, isFalse);
  });

  test('segmentado de 40 com o selecionado no secundário (D30)', () {
    final style = theme.segmentedButtonTheme.style!;
    expect(style.minimumSize?.resolve({})?.height, 40);
    expect(
      style.backgroundColor?.resolve({WidgetState.selected}),
      theme.colorScheme.secondaryContainer,
    );
  });

  test('campo contornado de raio 12 com o rótulo sempre em cima (D31)', () {
    final input = theme.inputDecorationTheme;
    expect(input.floatingLabelBehavior, FloatingLabelBehavior.always);
    expect(
      (input.border! as OutlineInputBorder).borderRadius,
      const BorderRadius.all(Radius.circular(AppShape.medium)),
    );
  });

  test('divisor de 1 em outlineVariant (D32)', () {
    expect(theme.dividerTheme.thickness, 1);
    expect(theme.dividerTheme.space, 1);
    expect(theme.dividerTheme.color, theme.colorScheme.outlineVariant);
  });
}
