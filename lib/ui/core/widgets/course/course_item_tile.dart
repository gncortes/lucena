import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_shape.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import '../../theme/canvas_symbols.dart';
import '../../keys/course_guide_keys.dart';
import 'training_badge.dart';

/// O estado de um item do mapa do curso (capítulo de finais ou lição da
/// Escola), como no canvas `CompAulaTile` v2.
enum CourseItemState {
  /// Feito: círculo verde-escuro com o visto.
  approved,

  /// Começado e ainda não feito: retomar pelo botão de reprodução.
  started,

  /// O recomendado agora: círculo primário e contorno de 2 dp.
  next,

  /// Liberado e ainda não começado.
  open,

  /// Ainda trancado: cadeado e título apagado.
  locked,
}

/// Um item do mapa do curso (canvas `CompAulaTile` v2): o círculo do estado,
/// o título e o resumo no topo, os selos embaixo ([tags]) e, nos finais, a
/// medalha da nota no canto (GradeMedal M2).
class CourseItemTile extends StatelessWidget {
  const CourseItemTile({
    required this.state,
    required this.title,
    this.summary,
    this.difficulty,
    this.tags = const [],
    this.medal,
    this.onTap,
    super.key,
  }) : assert(difficulty == null || (difficulty >= 1 && difficulty <= 3));

  /// O verde da concluída (canvas #2E6B3A).
  static const doneColor = AppColors.record;

  /// O círculo do estado (canvas: 40).
  static const circleSize = 40.0;

  /// A altura da medalha no canto (canvas: 20).
  static const medalSize = 20.0;

  final CourseItemState state;
  final String title;
  final String? summary;
  final int? difficulty;
  final List<Widget> tags;
  final Widget? medal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = this.summary;
    final difficulty = this.difficulty;
    final medal = this.medal;
    final (background, foreground, icon) = switch (state) {
      CourseItemState.approved => (
        doneColor,
        AppColors.white,
        CanvasSymbols.check,
      ),
      CourseItemState.started => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        CanvasSymbols.playArrow,
      ),
      CourseItemState.next => (
        colors.primary,
        colors.onPrimary,
        CanvasSymbols.playArrow,
      ),
      CourseItemState.open => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        CanvasSymbols.playArrow,
      ),
      CourseItemState.locked => (
        colors.surfaceContainerHighest,
        colors.outline,
        Icons.lock_rounded,
      ),
    };
    return Material(
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.card),
        side: state == CourseItemState.next
            ? BorderSide(color: colors.primary, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.lg,
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
                  color: foreground,
                  fill: icon == CanvasSymbols.playArrow ? 1 : null,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // CompAulaTile: gap 2 entre título e resumo.
                  spacing: 2,
                  children: [
                    Text(
                      title,
                      // CompAulaTile v2: 16/20 em 700.
                      style: theme.textTheme.titleMedium?.copyWith(
                        height: 20 / 16,
                        fontWeight: AppWeight.strong,
                        color: state == CourseItemState.locked
                            ? colors.onSurface.withValues(alpha: 0.38)
                            : null,
                      ),
                    ),
                    if (summary != null &&
                        summary.isNotEmpty &&
                        difficulty == null)
                      Text(
                        summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (summary != null &&
                        summary.isNotEmpty &&
                        difficulty != null)
                      Row(
                        spacing: AppSpacing.xs,
                        children: [
                          TrainingBadge.difficultyIcon(
                            context,
                            difficulty,
                            key: CourseGuideKeys.difficultyStar(title),
                          ),
                          Flexible(
                            child: Text(
                              summary,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    for (final tag in tags)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: tag,
                      ),
                  ],
                ),
              ),
              if (medal != null) SizedBox(height: medalSize, child: medal),
            ],
          ),
        ),
      ),
    );
  }
}
