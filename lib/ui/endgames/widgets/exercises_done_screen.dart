import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/endgame_lesson_cubit.dart';
import 'stars_row.dart';

/// O resultado dos exercícios de uma aula de final, depois do último: a nota,
/// e a escada das faixas (mínimo, bom, excelente, perfeito) com a do aluno em
/// destaque.
class ExercisesDoneScreen extends StatelessWidget {
  const ExercisesDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<EndgameLessonCubit>().state;
    if (state.lesson == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final grade = state.grade;
    final below = grade == ExerciseGrade.below;
    return Scaffold(
      key: ExercisesDoneKeys.screen,
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: scrollPadding(
                  context,
                  left: AppSpacing.screen,
                  top: AppSpacing.sm,
                  right: AppSpacing.screen,
                  bottom: AppSpacing.lg,
                ),
                children: [
                  Text(
                    below ? l10n.endgameFailedTitle : l10n.exercisesDoneTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Icon(
                    Icons.star_rounded,
                    size: 64,
                    color: StarsRow.color,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.endgameScore(state.score, state.maxScore),
                    key: ExercisesDoneKeys.score,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (below) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.exercisesDoneNeedMore(state.passScore),
                      key: ExercisesDoneKeys.needMore,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  for (final entry in state.gradeStars.entries)
                    _GradeTile(
                      grade: entry.key,
                      stars: entry.value,
                      reached: state.score >= entry.value,
                      current: entry.key == grade,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: FilledButton(
                key: ExercisesDoneKeys.back,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => context.pop(),
                child: Text(l10n.exerciseBack),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma faixa da escada: o nome, as estrelas que pede e, na faixa do aluno, o
/// destaque com "Você".
class _GradeTile extends StatelessWidget {
  const _GradeTile({
    required this.grade,
    required this.stars,
    required this.reached,
    required this.current,
  });

  final ExerciseGrade grade;
  final int stars;
  final bool reached;
  final bool current;

  String _name(AppLocalizations l10n) => switch (grade) {
    ExerciseGrade.passed => l10n.exerciseGradePassed,
    ExerciseGrade.good => l10n.exerciseGradeGood,
    ExerciseGrade.excellent => l10n.exerciseGradeExcellent,
    ExerciseGrade.perfect => l10n.exerciseGradePerfect,
    ExerciseGrade.below => '',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        key: current
            ? ExercisesDoneKeys.current
            : ExercisesDoneKeys.grade(grade.name),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: current ? colors.primaryContainer : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppShape.medium),
          border: current ? Border.all(color: colors.primary, width: 2) : null,
        ),
        child: Row(
          children: [
            Icon(
              reached
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: reached ? colors.primary : colors.outline,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _name(l10n),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                      color: reached ? null : colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l10n.endgameStars(stars),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (current)
              Text(
                l10n.exerciseGradeYou,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
