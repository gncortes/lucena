import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/use_cases/now.dart';

import '../../../domain/models/character.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/share/share_button.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../settings/widgets/about_screen.dart';
import '../view_models/endgame_lesson_cubit.dart';
import 'grade_widgets.dart';

/// O resultado dos exercícios de uma aula de final, depois do último: a
/// medalha da faixa, a nota e, com a aula aprovada, o diploma.
class ExercisesDoneScreen extends StatefulWidget {
  const ExercisesDoneScreen({super.key});

  @override
  State<ExercisesDoneScreen> createState() => _ExercisesDoneScreenState();
}

class _ExercisesDoneScreenState extends State<ExercisesDoneScreen> {
  // O diploma que vira imagem ao compartilhar.
  final _card = GlobalKey();

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
      // Compartilhar o diploma: só o ícone, no canto da barra.
      appBar: AppBar(
        actions: [
          if (!below)
            ShareIconButton(
              key: ExercisesDoneKeys.share,
              boundary: _card,
              tooltip: l10n.graduationShare,
              // A marca embaixo da imagem, como no diploma da escola.
              footer: 'Lucena · ${l10n.homeTagline}',
              fileName: 'lucena-${state.lesson!.id}.png',
              text: l10n.exercisesDoneShareText(
                state.texts.lessonTitle(state.lesson!.id),
                state.score,
                state.maxScore,
                AboutScreen.websiteFor(
                  Localizations.localeOf(context).languageCode,
                ).toString(),
              ),
            ),
        ],
      ),
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
                  // Passou: a medalha, a faixa, os pontos e o diploma são a
                  // imagem que vai no compartilhar.
                  if (!below)
                    RepaintBoundary(
                      key: _card,
                      child: ColoredBox(
                        key: ExercisesDoneKeys.shareCard,
                        color: theme.scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              GradeMedal(grade: grade),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                gradeName(l10n, grade),
                                key: ExercisesDoneKeys.current,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.exercisesDoneScore(
                                  state.score,
                                  state.maxScore,
                                ),
                                key: ExercisesDoneKeys.score,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _Diploma(state: state),
                            ],
                          ),
                        ),
                      ),
                    )
                  else ...[
                    GradeMedal(grade: grade),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.endgameFailedTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.exercisesDoneScore(state.score, state.maxScore),
                      key: ExercisesDoneKeys.score,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (below) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.exercisesDoneNeedMore(state.passScore),
                      key: ExercisesDoneKeys.needMore,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    // O Viktor anima a tentar de novo.
                    if (state.viktor case final viktor?) ...[
                      const SizedBox(height: AppSpacing.xl),
                      TeacherSpeech(
                        key: ExercisesDoneKeys.retrySpeech,
                        speechContext: SpeechContext.teaching,
                        teacher: viktor,
                        text: l10n.exercisesDoneRetrySpeech,
                        emotion: Emotion.calm,
                        avatarSize: 56,
                        speaks: true,
                      ),
                    ],
                  ],
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Passou: praticar o final de verdade. Não passou: refazer.
                  if (below)
                    FilledButton.icon(
                      key: ExercisesDoneKeys.redo,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.replay),
                      onPressed: () async {
                        final cubit = context.read<EndgameLessonCubit>();
                        final router = GoRouter.of(context);
                        final id = state.lesson!.id;
                        await cubit.redoExercises();
                        router.pushReplacement(
                          Routes.endgameExercisesIntro(id),
                        );
                      },
                      label: Text(l10n.endgameRedoExercises),
                    )
                  else
                    FilledButton.icon(
                      key: ExercisesDoneKeys.practice,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.sports_esports_outlined),
                      onPressed: () {
                        final practice = state.lesson!.practice;
                        context.pushReplacement(
                          Routes.setup(
                            practice.fen,
                            goal: practice.goal.code,
                            position: practice.positionId,
                          ),
                        );
                      },
                      label: Text(l10n.exercisesDonePractice),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  // Passou: concluir. Não passou: rever a lição, do começo.
                  if (below)
                    OutlinedButton.icon(
                      key: ExercisesDoneKeys.reviewLesson,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      onPressed: () {
                        final lesson = state.lesson!;
                        final first = lesson.lesson.sections.firstOrNull;
                        context.pushReplacement(
                          Routes.endgameLessonSteps(
                            lesson.id,
                            part: lesson.lesson.parts.isEmpty
                                ? null
                                : first?.id,
                          ),
                        );
                      },
                      label: Text(l10n.endgameLessonReview),
                    )
                  else
                    OutlinedButton(
                      key: ExercisesDoneKeys.back,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => context.pop(),
                      child: Text(l10n.exercisesDoneFinish),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// O diploma da aula: concedido ao aluno por concluir a aula, com o resumo do
/// que ela ensina, a faixa e os pontos, a data e o professor.
class _Diploma extends StatelessWidget {
  const _Diploma({required this.state});

  final EndgameLessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lesson = state.lesson!;
    final nickname = context.select(
      (ProfileCubit cubit) => cubit.state?.nickname ?? '',
    );
    final now = context.read<Now?>()?.call();
    final date = now == null
        ? ''
        : DateFormat.yMMMMd(Localizations.localeOf(context).toString())
              .format(now);
    final summary = state.texts.lessonSummary(lesson.id);
    return Container(
      key: ExercisesDoneKeys.diploma,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        border: Border.all(color: colors.primary, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppShape.medium),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 48,
              color: colors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.endgamesTitle.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 2,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.graduationDiploma,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.graduationAwardedTo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            Text(
              nickname.isEmpty ? l10n.profileNicknameDefault : nickname,
              key: ExercisesDoneKeys.diplomaName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              // Resume o desempenho, sem números.
              l10n.exercisesDoneDiplomaFor(
                state.grade.name,
                state.texts.lessonTitle(lesson.id),
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (summary != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                summary,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _SignatureLine(
                    value: date,
                    label: l10n.graduationDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: _SignatureLine(
                    value: state.viktor?.name ?? '',
                    label: l10n.graduationTeacher,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma linha de assinatura: o valor sobre um traço e o rótulo embaixo.
class _SignatureLine extends StatelessWidget {
  const _SignatureLine({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Divider(height: 1, color: colors.outline),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
