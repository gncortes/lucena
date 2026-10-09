import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/celebration.dart';
import '../../core/widgets/teacher_speech.dart';
import '../view_models/lesson_cubit.dart';

/// O ritmo da demonstração, do spike `docs/spikes/T51-ritmo.md`: depois de
/// cada fala, uma pausa; sem voz, um tempo de leitura pelo tamanho dela.
abstract final class DemoPace {
  static const pauseMs = 600;
  static const minReadMs = 2500;
  static const msPerChar = 65;
}

/// O tempo de pensar, no topo da tela: o relógio e a barra que esvazia,
/// como no desafio das estrelas.
class ThinkClock extends StatelessWidget {
  const ThinkClock({required this.state, super.key});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final left = state.thinkLeft;
    if (left == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final total = state.thinkTime.inMilliseconds;
    final fraction = total == 0 ? 0.0 : left.inMilliseconds / total;
    final seconds = (left.inMilliseconds / 1000).ceil();
    final label =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Semantics(
      label: context.l10n.lessonThinkLeft(label),
      excludeSemantics: true,
      child: Padding(
        key: LessonKeys.thinkClock,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_bottom_outlined,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppShape.small),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  // A barra anda contínua entre um quarto de segundo e outro.
                  duration: AppMotion.of(context).state,
                  curve: AppMotion.linear,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Os controles da demonstração: repetir do começo, voltar um lance (e
/// parar ali) e avançar (e seguir sozinha).
class DemoControls extends StatelessWidget {
  const DemoControls({required this.state, required this.height, super.key});

  final LessonState state;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LessonCubit>();
    final colors = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;
    Widget button(
      Key key,
      IconData icon,
      String tooltip,
      VoidCallback? onPressed, {
      bool main = false,
    }) => FloatingActionButton(
      key: key,
      heroTag: null,
      shape: const CircleBorder(),
      elevation: main ? 4 : 2,
      backgroundColor: main ? colors.primary : colors.surface,
      foregroundColor: main ? colors.onPrimary : colors.primary,
      tooltip: tooltip,
      onPressed: onPressed,
      child: Icon(icon),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [background.withValues(alpha: 0), background],
          stops: const [0, 0.5],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Voltar ao passo anterior da lição, como nos outros passos.
            button(
              LessonKeys.backButton,
              Icons.arrow_back,
              l10n.lessonPrevious,
              state.step == 0 ? null : cubit.back,
            ),
            button(
              LessonKeys.demoReplay,
              Icons.replay,
              l10n.lessonDemoReplay,
              cubit.demoReplay,
            ),
            button(
              LessonKeys.demoBack,
              Icons.skip_previous_rounded,
              l10n.lessonDemoBack,
              state.demoMove == 0 ? null : cubit.demoBack,
            ),
            button(
              LessonKeys.demoPause,
              state.demoPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              state.demoPlaying ? l10n.lessonDemoPause : l10n.lessonDemoPlay,
              cubit.demoTogglePause,
            ),
            button(
              LessonKeys.demoForward,
              Icons.skip_next_rounded,
              l10n.lessonDemoForward,
              cubit.demoForward,
              main: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// O fim de uma parte: o selo de feito, "Parte N concluída" e a próxima
/// parte recomendada (ou o teste final, com todas feitas).
class PartFinished extends StatelessWidget {
  const PartFinished({required this.state, super.key});

  final LessonState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lessonId = state.lesson!.id;
    final part = state.part!;
    final next = state.nextPart;
    final viktor = state.viktor;
    final motion = AppMotion.of(context);
    final summary = state.texts.partSummary(lessonId, part.id);
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: LessonKeys.partFinished,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: motion.celebrate,
                      curve: AppMotion.pop,
                      builder: (context, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: colors.primaryContainer,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 52,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      // Na última: todas as etapas, e o convite para a prova.
                      next == null
                          ? l10n.lessonAllPartsDone
                          : l10n.lessonPartDone(state.partNumber),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      next == null
                          ? l10n.lessonAllPartsDoneBody
                          : state.texts.partTitle(lessonId, part.id) ?? '',
                      key: next == null ? LessonKeys.allPartsDone : null,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    // O que a etapa ensinou: para bater o olho e decidir se
                    // vale rever.
                    if (summary != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        key: LessonKeys.partSummary,
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppShape.medium),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.lessonPartLearned,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(summary, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                    if (viktor != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      TeacherSpeech(
                        teacher: viktor,
                        text: state.speech,
                        emotion: state.emotion,
                        avatarSize: 56,
                        speaks: true,
                        speechContext: SpeechContext.teaching,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Fixos embaixo: rever esta etapa ou seguir.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.sm,
                AppSpacing.screen,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: LessonKeys.reviewPartButton,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: () => context.pushReplacement(
                        Routes.endgameLessonSteps(lessonId, part: part.id),
                      ),
                      icon: const Icon(Icons.replay),
                      label: Text(l10n.lessonReviewPart),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      key: LessonKeys.nextPartButton,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      // Na última etapa, o teste final (pela introdução).
                      onPressed: () => context.pushReplacement(
                        next == null
                            ? Routes.endgameExercisesIntro(lessonId)
                            : Routes.endgameLessonSteps(lessonId, part: next),
                      ),
                      icon: Icon(
                        next == null
                            ? Icons.quiz_outlined
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        next == null
                            ? l10n.lessonToFinalTest
                            : l10n.lessonPartNext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!motion.disabled) const Celebration(),
      ],
    );
  }
}
