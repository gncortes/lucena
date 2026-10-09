import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/endgame_lesson_cubit.dart';
import 'grade_widgets.dart';
import 'stars_row.dart';

/// Antes dos exercícios: o Viktor explica como pensar (uns 5 minutos por
/// posição) e como a nota fecha; chips com o tamanho do teste e a nota
/// mínima; o que vale cada estrela; o aviso de que depois dá para voltar a
/// qualquer exercício e analisar no Lichess; e, fixo embaixo, o botão que
/// abre o primeiro (ou o próximo).
class ExercisesIntroScreen extends StatelessWidget {
  const ExercisesIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final state = context.watch<EndgameLessonCubit>().state;
    final lesson = state.lesson;
    final viktor = state.viktor;
    final next = state.nextExercise;
    // As faixas, da melhor para a menor; numa aula pequena duas podem pedir
    // o mesmo, e aí só a de cima vale.
    final tiers = <MapEntry<ExerciseGrade, int>>[];
    for (final entry in state.gradeStars.entries.toList().reversed) {
      if (tiers.isEmpty || tiers.last.value != entry.value) tiers.add(entry);
    }
    final facts = [
      (
        Icons.format_list_numbered_rounded,
        l10n.endgameTestCount(state.exerciseCount),
        l10n.exercisesIntroCountBody,
      ),
      (
        Icons.star_outline_rounded,
        l10n.exercisesIntroMinTitle(state.passScore),
        l10n.exercisesIntroMinBody(state.maxScore),
      ),
      (
        Icons.schedule_rounded,
        l10n.exercisesIntroChipThink,
        l10n.exercisesIntroThinkBody,
      ),
    ];
    return Scaffold(
      key: ExercisesIntroKeys.screen,
      appBar: AppBar(title: Text(l10n.endgameFinalTest)),
      body: SafeArea(
        child: lesson == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Expanded(
                    // Tela curta: tudo montado de uma vez.
                    child: SingleChildScrollView(
                      padding: scrollPadding(
                        context,
                        left: AppSpacing.screen,
                        top: AppSpacing.lg,
                        right: AppSpacing.screen,
                        bottom: AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (viktor != null)
                            TeacherSpeech(
                              speechContext: SpeechContext.teaching,
                              teacher: viktor,
                              text: l10n.exercisesIntroSpeech,
                              emotion: Emotion.focused,
                              avatarSize: 56,
                              speaks: true,
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          // Os três pontos do teste, cada um com o porquê.
                          for (final (icon, title, body) in facts) ...[
                            _FactCard(icon: icon, title: title, body: body),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          // O que vale cada estrela, e o que erro e dica tiram.
                          _InfoCard(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final points in [3, 2, 1]) ...[
                                      ValueStar(points: points, size: 26),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        l10n.exercisePoints(points),
                                        style: theme.textTheme.labelLarge,
                                      ),
                                      if (points > 1)
                                        const SizedBox(width: AppSpacing.lg),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  l10n.exercisesIntroStarLegend,
                                  key: ExercisesIntroKeys.legend,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // As faixas da nota: o que cada uma pede.
                          _InfoCard(
                            child: Column(
                              key: ExercisesIntroKeys.tiers,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final entry in tiers)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 56,
                                          child: GradeMedal(
                                            grade: entry.key,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                gradeName(l10n, entry.key),
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              Text(
                                                l10n.exercisesDoneScore(
                                                  entry.value,
                                                  state.maxScore,
                                                ),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Depois: a lista fica aberta para rever e analisar.
                          _InfoCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.open_in_new_rounded,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    l10n.exercisesIntroAfter,
                                    key: ExercisesIntroKeys.after,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Fixo embaixo, como o "Continuar" da aula.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.sm,
                      AppSpacing.screen,
                      AppSpacing.md,
                    ),
                    child: FilledButton.icon(
                      key: ExercisesIntroKeys.start,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: next == null
                          ? null
                          : () => context.pushReplacement(
                              Routes.endgameExercise(lesson.id, next.id),
                            ),
                      label: Text(
                        state.solved == 0
                            ? l10n.endgameExercisesStart
                            : l10n.endgameExercisesContinue,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Um card discreto de informação.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: child,
    );
  }
}

/// Um ponto do teste: ícone num círculo, o título e a explicação.
class _FactCard extends StatelessWidget {
  const _FactCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return _InfoCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primaryContainer,
            child: Icon(icon, size: 22, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
