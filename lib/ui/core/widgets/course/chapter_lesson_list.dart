import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_icon_size.dart';
import '../../theme/app_shape.dart';
import '../../theme/app_spacing.dart';

/// O tipo de uma linha da lista de lições do capítulo (canvas
/// `CompCapituloTile` v2).
enum ChapterRowKind {
  /// Feita: visto no círculo verde-escuro.
  done,

  /// A recomendada agora: fundo primary-container e resumo embaixo.
  recommended,

  /// Os exercícios práticos, último item depois do divisor.
  exercises,

  /// As outras: ainda não feitas e não recomendadas.
  other,
}

/// O cartão com as lições do capítulo e, depois de um divisor, a linha dos
/// exercícios práticos.
class ChapterLessonList extends StatelessWidget {
  const ChapterLessonList({required this.rows, this.exercises, super.key});

  final List<Widget> rows;
  final Widget? exercises;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final exercises = this.exercises;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        // Canvas: padding 8 6.
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: 6,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...rows,
            if (exercises != null) ...[
              Padding(
                // Canvas: margin 4 10.
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: 10,
                ),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: colors.outlineVariant,
                ),
              ),
              exercises,
            ],
          ],
        ),
      ),
    );
  }
}

/// Uma linha da [ChapterLessonList]: círculo de 28, o número ("5.1") numa
/// coluna de 28 e o título; a recomendada traz o resumo embaixo.
class ChapterLessonRow extends StatelessWidget {
  const ChapterLessonRow({
    required this.kind,
    required this.number,
    required this.title,
    this.summary,
    this.onTap,
    super.key,
  });

  /// A altura mínima da linha (alvo de toque).
  static const minHeight = 48.0;

  /// O círculo e a coluna do número (canvas: 28).
  static const circleSize = 28.0;

  /// O recuo do resumo: círculo, número e os dois espaços (canvas: 80).
  static const summaryInset = circleSize * 2 + AppSpacing.md * 2;

  final ChapterRowKind kind;
  final String number;
  final String title;
  final String? summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final recommended = kind == ChapterRowKind.recommended;
    final summary = this.summary;
    final (background, foreground, icon) = switch (kind) {
      ChapterRowKind.done => (AppColors.record, AppColors.white, Icons.check),
      ChapterRowKind.recommended => (
        colors.primary,
        colors.onPrimary,
        Icons.play_arrow_rounded,
      ),
      ChapterRowKind.exercises => (
        colors.secondaryContainer,
        colors.primary,
        Icons.quiz_rounded,
      ),
      ChapterRowKind.other => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        Icons.play_arrow_rounded,
      ),
    };
    final strong = recommended || kind == ChapterRowKind.exercises;
    return Material(
      color: recommended ? colors.primaryContainer : AppColors.clear,
      borderRadius: BorderRadius.circular(AppShape.medium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minHeight),
          child: Padding(
            // Canvas: 10 10 12 10 na recomendada, 0 10 nas outras.
            padding: recommended
                ? const EdgeInsets.fromLTRB(10, 10, 10, 12)
                : const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: BoxDecoration(
                        color: background,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: AppIconSize.small,
                        color: foreground,
                      ),
                    ),
                    SizedBox(
                      width: circleSize,
                      child: Text(
                        number,
                        // Canvas: 13/20 em 500.
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          height: 20 / 13,
                          color: colors.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        // Canvas: 15/20, 600 na recomendada e nos exercícios.
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          height: 20 / 15,
                          letterSpacing: 0,
                          fontWeight: strong
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                if (recommended && summary != null && summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: summaryInset,
                      top: AppSpacing.xs,
                    ),
                    child: Text(
                      summary,
                      // Canvas: 14/19.
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 19 / 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
