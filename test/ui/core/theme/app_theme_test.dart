import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';

// Contraste da WCAG entre duas cores (de 1 a 21).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

void main() {
  test('sem cor escolhida: azul no claro e verde no escuro', () {
    expect(
      AppTheme.of(Brightness.light),
      same(AppTheme.of(Brightness.light, accent: AppAccent.blue)),
    );
    expect(
      AppTheme.of(Brightness.dark),
      same(AppTheme.of(Brightness.dark, accent: AppAccent.green)),
    );
  });

  test('cada cor tem um tema claro e um escuro, diferentes entre as cores', () {
    for (final brightness in Brightness.values) {
      final primaries = <Color>{};
      final backgrounds = <Color>{};
      for (final accent in AppAccent.values) {
        final theme = AppTheme.of(brightness, accent: accent);
        expect(theme.brightness, brightness);
        primaries.add(theme.colorScheme.primary);
        backgrounds.add(theme.scaffoldBackgroundColor);
      }
      expect(primaries, hasLength(AppAccent.values.length));
      expect(backgrounds, hasLength(AppAccent.values.length));
    }
  });

  test('em toda cor e tema, o texto continua legível', () {
    for (final brightness in Brightness.values) {
      for (final accent in AppAccent.values) {
        final theme = AppTheme.of(brightness, accent: accent);
        final scheme = theme.colorScheme;
        final background = theme.scaffoldBackgroundColor;
        final pairs = {
          'botão': (scheme.onPrimary, scheme.primary),
          'destaque': (scheme.onPrimaryContainer, scheme.primaryContainer),
          'destaque secundário': (
            scheme.onSecondaryContainer,
            scheme.secondaryContainer,
          ),
          'texto no fundo': (scheme.onSurface, background),
          'texto apagado no fundo': (scheme.onSurfaceVariant, background),
          'cor principal no fundo': (scheme.primary, background),
        };
        for (final MapEntry(key: name, value: (text, surface))
            in pairs.entries) {
          expect(
            contrast(text, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name em ${accent.name} ${brightness.name}',
          );
        }
      }
    }
  });
}
