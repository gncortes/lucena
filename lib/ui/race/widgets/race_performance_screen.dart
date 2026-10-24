import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/use_cases/race_diagnosis.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/next_steps.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/race_performance_cubit.dart';
import 'race_progress_card.dart';

/// "Seu desempenho" (canvas V2 · Ligações, L6b): primeiro o que o jogador já
/// domina; depois onde pode melhorar (acertos, sem vermelho, do pior ao
/// melhor); nos próximos passos, a aula liberada de cada final a melhorar e
/// as posições do mais fraco no catálogo.
class RacePerformanceScreen extends StatelessWidget {
  const RacePerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: RaceKeys.performanceScreen,
      appBar: LucenaAppBar(title: Text(l10n.racePerformanceTitle)),
      body: BlocBuilder<RacePerformanceCubit, RacePerformanceState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          final diagnosis = state.diagnosis;
          final weakest = diagnosis.weakest;
          return ListView(
            padding: scrollPadding(
              context,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              top: AppSpacing.sm,
            ),
            children: [
              if (!diagnosis.ready)
                RaceProgressCard(diagnosis: diagnosis)
              else ...[
                if (diagnosis.mastered.isNotEmpty) ...[
                  _Mastered(scores: diagnosis.mastered),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (diagnosis.toImprove.isNotEmpty) ...[
                  _ToImprove(scores: diagnosis.toImprove),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (weakest != null) ...[
                  NextSteps(
                    steps: [
                      for (final lesson in state.lessons)
                        NextStep(
                          id: 'lesson.${lesson.lessonId}',
                          icon: Icons.school,
                          title: l10n.racePerformanceLessonTitle(
                            endgameName(l10n, lesson.subcategory),
                          ),
                          body: _lessonBody(l10n, lesson.subcategory),
                          onTap: () => context.push(
                            lesson.school
                                ? Routes.lessonScript(lesson.lessonId)
                                : Routes.endgameLesson(lesson.lessonId),
                          ),
                        ),
                      NextStep(
                        id: 'practice',
                        icon: Icons.sports_esports,
                        title: l10n.nextStepsPractice(
                          endgameName(l10n, weakest.subcategory),
                        ),
                        body: l10n.racePerformancePracticeBody,
                        onTap: () => context.push(
                          Routes.catalogCategory(weakest.category),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                Text(
                  l10n.racePerformanceFooter,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// O que a aula ensina, sem o nome do curso.
  static String _lessonBody(AppLocalizations l10n, String subcategory) =>
      switch (subcategory) {
        'queen' => l10n.racePerformanceLessonQueen,
        'rook' => l10n.racePerformanceLessonRook,
        'pawnVsKing' => l10n.racePerformanceLessonPawnVsKing,
        'knightBishopVsKing' => l10n.racePerformanceLessonKnightBishop,
        'queenVsRook' => l10n.racePerformanceLessonQueenVsRook,
        'rookPawnVsRook' => l10n.racePerformanceLessonLucena,
        _ => '',
      };
}

/// Um cartão da tela: o ícone e o título no alto, o conteúdo embaixo.
class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.children,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              Icon(icon, color: iconColor),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    ),
  );
}

/// "O que você já domina": um chip verde por final.
class _Mastered extends StatelessWidget {
  const _Mastered({required this.scores});

  final List<RaceFinalScore> scores;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final green = ChangeColors.of(context, up: true);
    return _PerformanceCard(
      key: RaceKeys.performanceMastered,
      icon: Icons.verified,
      iconColor: green,
      title: l10n.racePerformanceMastered,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final score in scores)
              InfoChip(
                key: RaceKeys.performanceChip(score.subcategory),
                icon: Icons.check,
                label: endgameName(l10n, score.subcategory),
                compact: true,
                background: green.withValues(alpha: 0.16),
                foreground: green,
              ),
          ],
        ),
      ],
    );
  }
}

/// "Onde você pode melhorar": cada final com os acertos e a barra.
class _ToImprove extends StatelessWidget {
  const _ToImprove({required this.scores});

  final List<RaceFinalScore> scores;

  /// A barra de acertos (canvas: 72 × 6).
  static const _barWidth = 72.0;
  static const _barHeight = 6.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _PerformanceCard(
      key: RaceKeys.performanceToImprove,
      icon: Icons.fitness_center,
      iconColor: colors.primary,
      title: l10n.racePerformanceToImprove,
      children: [
        for (final score in scores)
          Row(
            key: RaceKeys.performanceRow(score.subcategory),
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: Text(
                  endgameName(l10n, score.subcategory),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Text(
                l10n.racePerformanceCorrects(score.corrects, score.total),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(_barHeight),
                child: SizedBox(
                  width: _barWidth,
                  height: _barHeight,
                  child: LinearProgressIndicator(
                    value: score.accuracy,
                    color: colors.primary,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
