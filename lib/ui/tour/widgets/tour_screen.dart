import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/game_setup.dart';
import '../../../domain/models/rating_level.dart';
import '../../../routing/routes.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
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
        context.go(Routes.home);
      },
      builder: (context, state) {
        if (!state.ready) return const Scaffold(key: TourKeys.screen);
        final step = state.step;
        final total = TourStep.values.length;
        return Scaffold(
          key: TourKeys.screen,
          appBar: AppBar(
            automaticallyImplyLeading: false,
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
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: step.isLast
                        ? _LevelStep(key: TourKeys.step(step), state: state)
                        : _InfoStep(key: TourKeys.step(step), step: step),
                  ),
                ),
                Semantics(
                  label: l10n.tourStep(step.index + 1, total),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < total; index++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(3),
                            width: index == step.index ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == step.index
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
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
                          step.isLast ? l10n.tourStart : l10n.tourNext,
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
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                icon,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
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
              Icon(Icons.flag_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.tourLevelStart(
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
