import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_shape.dart';
import 'package:lucena/ui/core/theme/app_spacing.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/core/theme/app_tokens.dart';

void main() {
  test('os temas claro e escuro trazem os tokens de forma e espaço', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final tokens = theme.extension<AppTokens>()!;
      expect(tokens.radiusSmall, AppShape.small);
      expect(tokens.radiusMedium, AppShape.medium);
      expect(tokens.radiusLarge, AppShape.large);
      expect(tokens.screenPadding, AppSpacing.screen);
      expect(tokens.betweenCards, AppSpacing.betweenCards);
    }
  });

  test('os cartões usam o raio grande', () {
    final shape = AppTheme.light.cardTheme.shape! as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      const BorderRadius.all(Radius.circular(AppShape.large)),
    );
  });

  testWidgets('fora do tema do app, os padrões', (tester) async {
    late AppTokens tokens;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          tokens = AppTokens.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(tokens.radiusLarge, AppShape.large);
  });
}
