import 'package:flutter/material.dart';

import '../../../domain/models/app_accent.dart';
import '../../../domain/models/app_theme_mode.dart';
import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme_mode_ui.dart';
import '../theme/app_motion.dart';
import '../theme/app_shape.dart';

/// Os três temas lado a lado, cada um com uma miniatura do app nas cores
/// dele ([accent] é a cor do app escolhida).
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({
    required this.selected,
    required this.accent,
    required this.onSelected,
    required this.keyOf,
    super.key,
  });

  final AppThemeMode selected;
  final AppAccent? accent;
  final ValueChanged<AppThemeMode> onSelected;
  final Key Function(AppThemeMode mode) keyOf;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          for (final mode in AppThemeMode.values)
            Expanded(
              child: _ModeCard(
                key: keyOf(mode),
                mode: mode,
                accent: accent,
                label: mode.label(l10n),
                selected: mode == selected,
                onTap: () => onSelected(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.accent,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AppThemeMode mode;
  final AppAccent? accent;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppShape.large);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.state,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                width: 2,
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppShape.medium),
                    // A miniatura não espelha: claro à esquerda, escuro à
                    // direita em qualquer idioma.
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (mode != AppThemeMode.dark)
                            Expanded(
                              child: _MiniScreen(
                                theme: AppTheme.of(
                                  Brightness.light,
                                  accent: accent,
                                ),
                              ),
                            ),
                          if (mode != AppThemeMode.light)
                            Expanded(
                              child: _MiniScreen(
                                theme: AppTheme.of(
                                  Brightness.dark,
                                  accent: accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      mode.icon,
                      size: 16,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w700 : null,
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Um pedaço de tela do app em miniatura: fundo, um cartão e um botão.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    Widget bar(Color color, double widthFactor) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppShape.small),
        ),
      ),
    );
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            bar(scheme.onSurface.withValues(alpha: 0.7), 0.7),
            bar(scheme.onSurfaceVariant.withValues(alpha: 0.4), 1),
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppShape.small),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
