import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/position_board.dart';
import '../../endgames/widgets/endgame_ui.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/home_cubit.dart';
import 'home_actions.dart';

/// O cartão azul de cima da tela inicial (T83, canvas `CompHeroContinuar`):
/// o retrato, o ponto em que a pessoa está e a miniatura numa linha; embaixo,
/// o lugar do app, a barra (só com progresso) e o botão. Nada além disso.
class HeroCard extends StatelessWidget {
  const HeroCard({required this.state, super.key});

  /// A miniatura da posição.
  static const board = 60.0;

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final data = _data(context);
    if (data == null) return const SizedBox.shrink();
    return _HeroLayout(data: data);
  }

  _HeroData? _data(BuildContext context) {
    final l10n = context.l10n;
    final school = state.school;
    final endgame = state.endgame;
    final train = state.trainGoal;
    final current = state.current;
    final next = state.next;
    return switch (state.hero) {
      null => null,
      HomeHero.firstSteps => _HeroData(
        label: l10n.homeHeroFirstSteps,
        title: l10n.boardMoveMethod,
        action: l10n.homeHeroStart,
        avatar: state.character,
        fen: GameRules.initial.fen,
        onPressed: () => context.push(Routes.boardControls),
      ),
      HomeHero.school when school != null => _HeroData(
        label: l10n.homeHeroSchool,
        title: l10n.homeHeroLesson(school.done + 1),
        progress: school.total == 0 ? 0 : school.done / school.total,
        action: l10n.homeContinue,
        avatar: school.teacher,
        fen: GameRules.initial.fen,
        onPressed: () => school.ongoingLessonId == null
            ? context.go(Routes.school)
            : context.push(
                Routes.lessonScript(school.ongoingLessonId!, origin: 'home'),
              ),
      ),
      HomeHero.journey when current != null && next != null => _HeroData(
        label: l10n.homeJourney,
        title:
            state.character?.name ??
            opponentRefLabel(l10n, current.rung.opponent),
        progress: current.rung.challenges.isEmpty
            ? 0
            : current.completed.length / current.rung.challenges.length,
        action: state.journeySaved ? l10n.homeHeroResume : l10n.homeHeroPlay,
        avatar: state.character,
        // O retrato e o tabuleiro voam até a tela do desafio.
        avatarTag: opponentHeroTag(current.rung.id),
        fen: next.position.fen,
        boardTag: challengeBoardTag(next.id),
        onPressed: () => continueJourney(context, state),
      ),
      HomeHero.endgame when endgame != null => _HeroData(
        label: l10n.homeEndgames,
        title: endgame.title,
        progress: endgame.progress,
        action: endgame.recommended ? l10n.homeHeroStart : l10n.homeContinue,
        avatar: endgame.teacher,
        fen: endgame.fen,
        boardTag: endgame.openExerciseId == null
            ? null
            : exerciseHeroTag(endgame.lessonId, endgame.openExerciseId!),
        onPressed: () =>
            context.push(endgame.route, extra: endgame.exerciseFen),
      ),
      HomeHero.courseDone => _HeroData(
        label: l10n.homeEndgames,
        title: l10n.homeHeroCourseDone,
        action: l10n.homeGoalTrain,
        avatar: state.teacher,
        onPressed: () => context.go(Routes.catalog),
      ),
      HomeHero.train when train != null => _HeroData(
        label: l10n.homeTrain,
        title: endgameName(l10n, train.suggestion.subcategory.key),
        progress: train.suggestion.total == 0
            ? 0
            : train.suggestion.done / train.suggestion.total,
        action: l10n.homeGoalTrain,
        avatar: state.character ?? state.teacher,
        fen: train.fen,
        onPressed: () => context.go(
          Routes.catalogCategory(
            train.suggestion.subcategory.category,
            subcategory: train.suggestion.subcategory.key,
          ),
        ),
      ),
      HomeHero.speedrun => _HeroData(
        label: l10n.homeSpeedrun,
        title: l10n.homeHeroSpeedrun,
        action: l10n.homeHeroPlay,
        avatar: Character.stockfish,
        onPressed: () => context.go(Routes.speedruns),
      ),
      _ => null,
    };
  }
}

class _HeroData {
  const _HeroData({
    required this.label,
    required this.title,
    required this.action,
    required this.onPressed,
    this.progress = 0,
    this.avatar,
    this.avatarTag,
    this.fen,
    this.boardTag,
  });

  final String label;
  final String title;
  final String action;
  final VoidCallback onPressed;

  /// De 0 a 1. Zero: sem barra.
  final double progress;
  final Character? avatar;
  final Object? avatarTag;
  final String? fen;
  final Object? boardTag;
}

class _HeroLayout extends StatelessWidget {
  const _HeroLayout({required this.data});

  final _HeroData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final on = colors.onPrimary;
    final avatar = data.avatar;
    final avatarTag = data.avatarTag;
    final fen = data.fen;
    Widget? portrait;
    if (avatar != null) {
      portrait = CharacterAvatar(
        character: avatar,
        size: CharacterAvatar.lesson,
        radius: AppShape.small,
      );
      if (avatarTag != null) portrait = Hero(tag: avatarTag, child: portrait);
    }
    return Material(
      key: HomeKeys.goalCard,
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppShape.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              Row(
                spacing: AppSpacing.md,
                children: [
                  ?portrait,
                  Expanded(
                    child: Text(
                      data.title,
                      key: HomeKeys.goalTitle,
                      maxLines: 2,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: on,
                        fontWeight: AppWeight.heavy,
                      ),
                    ),
                  ),
                  if (fen != null)
                    PositionBoard(
                      key: HomeKeys.heroBoard,
                      fen: fen,
                      size: HeroCard.board,
                      heroTag: data.boardTag,
                    ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      data.label,
                      key: HomeKeys.heroLabel,
                      maxLines: 1,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: on.withValues(alpha: 0.85),
                        fontWeight: AppWeight.strong,
                      ),
                    ),
                  ),
                  if (data.progress > 0) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      // A barra branca sobre o azul.
                      child: Theme(
                        data: theme.copyWith(
                          colorScheme: colors.copyWith(primary: on),
                        ),
                        child: AnimatedProgress(
                          key: HomeKeys.heroProgress,
                          value: data.progress,
                          backgroundColor: on.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    key: HomeKeys.goalAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: on,
                      foregroundColor: colors.primary,
                      minimumSize: const Size(0, kButtonHeightPill),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.md,
                        0,
                        AppSpacing.lg,
                        0,
                      ),
                      // O desenho tem 36; o toque, os 48 do Material (D6).
                      tapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.standard,
                      shape: const StadiumBorder(),
                    ),
                    onPressed: data.onPressed,
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      size: AppIconSize.button,
                    ),
                    label: Text(data.action),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
