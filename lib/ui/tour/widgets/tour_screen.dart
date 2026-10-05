import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/rating_level.dart';
import '../../../routing/routes.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../../domain/models/character.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/widgets/step_progress.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/rating_level_sheet.dart';
import '../view_models/tour_cubit.dart';

/// O tour da primeira abertura: o que é o app, rating, Jornada, finais,
/// adversários, speedrun e recordes, e no fim o nível do jogador.
class TourScreen extends StatelessWidget {
  const TourScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TourCubit>();
    return BlocConsumer<TourCubit, TourState>(
      listenWhen: (previous, current) => current.finished && !previous.finished,
      listener: (context, state) {
        // A faixa escolhida já está no perfil.
        context.read<ProfileCubit>().load();
        // O iniciante vai direto para as aulas (a tela inicial fica embaixo).
        context.go(state.toSchool ? Routes.school : Routes.home);
      },
      builder: (context, state) {
        if (!state.ready) return const Scaffold(key: TourKeys.screen);
        final step = state.step;
        final total = TourStep.values.length;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        // Avançando, o passo novo entra pelo fim da linha e o velho sai pelo
        // começo; voltando, ao contrário. Em árabe, espelhado.
        final sign = (state.forward ? 1.0 : -1.0) * (rtl ? -1 : 1);
        final currentKey = TourKeys.step(step);
        return Scaffold(
          key: TourKeys.screen,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Semantics(
              label: l10n.tourStep(step.index + 1, total),
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: StepProgress(
                        key: TourKeys.progress,
                        total: total,
                        value: step.index + 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${step.index + 1}/$total',
                      key: TourKeys.stepCounter,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (!step.isLast)
                TextButton(
                  key: TourKeys.skipButton,
                  onPressed: cubit.skip,
                  child: Text(l10n.tourSkip),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (state.viktor case final viktor?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: TeacherSpeech(
                      key: TourKeys.viktor,
                      teacher: viktor,
                      text: state.speech,
                      emotion: step.isLast && state.toSchool
                          ? Emotion.happy
                          : Emotion.calm,
                      avatarSize: 64,
                      bubbleKey: TourKeys.speech,
                    ),
                  ),
                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 380),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final entering = child.key == currentKey;
                        final offset = Tween(
                          begin: Offset((entering ? 1 : -1) * sign * 0.35, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offset,
                            child: child,
                          ),
                        );
                      },
                      child: step.isLast
                          ? _LevelStep(key: currentKey, state: state)
                          : _InfoStep(key: currentKey, step: step),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      if (step.index > 0)
                        TextButton(
                          key: TourKeys.backButton,
                          onPressed: cubit.back,
                          child: Text(l10n.tourBack),
                        ),
                      const Spacer(),
                      FilledButton(
                        key: step.isLast
                            ? TourKeys.startButton
                            : TourKeys.nextButton,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(140, 48),
                        ),
                        onPressed: step.isLast ? cubit.finish : cubit.next,
                        child: Text(
                          !step.isLast
                              ? l10n.tourNext
                              : state.toSchool
                              ? l10n.tourStartLessons
                              : l10n.tourStart,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoStep extends StatelessWidget {
  const _InfoStep({required this.step, super.key});

  final TourStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, title, body) = switch (step) {
      TourStep.goal => (
        Icons.school_outlined,
        l10n.tourGoalTitle,
        l10n.tourGoalBody,
      ),
      TourStep.rating => (
        Icons.trending_up,
        l10n.tourRatingTitle,
        l10n.tourRatingBody,
      ),
      TourStep.journey => (
        Icons.flag_rounded,
        l10n.tourJourneyTitle,
        l10n.tourJourneyBody,
      ),
      TourStep.endgames => (
        Icons.grid_on_outlined,
        l10n.tourEndgamesTitle,
        l10n.tourEndgamesBody,
      ),
      TourStep.opponents => (
        Icons.chat_bubble_outline,
        l10n.tourOpponentsTitle,
        l10n.tourOpponentsBody,
      ),
      TourStep.speedrun => (
        Icons.timer_outlined,
        l10n.tourSpeedrunTitle,
        l10n.tourSpeedrunBody,
      ),
      TourStep.records => (
        Icons.emoji_events_outlined,
        l10n.tourRecordsTitle,
        l10n.tourRecordsBody,
      ),
      TourStep.level => (Icons.person_outline, '', ''),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: CircleAvatar(
                radius: 44,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  size: 44,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Qual é o seu nível atual?": as faixas do perfil, e o degrau em que a
/// Jornada vai começar.
class _LevelStep extends StatelessWidget {
  const _LevelStep({required this.state, super.key});

  final TourState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<TourCubit>();
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tourLevelTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                l10n.tourLevelBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final level in RatingLevel.values)
          RatingLevelOption(
            key: TourKeys.level(level),
            level: level,
            selected: level == state.level,
            onTap: () => cubit.setLevel(level),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Row(
            children: [
              Icon(
                state.toSchool ? Icons.school_outlined : Icons.flag_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.toSchool
                      ? l10n.tourLevelSchool
                      : l10n.tourLevelStart(
                          OpponentKind.maia.label(
                            l10n,
                            level: int.parse(state.startRung),
                          ),
                        ),
                  key: TourKeys.startRung,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
