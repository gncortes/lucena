import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/models/home_layout.dart';
import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/position_board.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/home_cubit.dart';
import 'where_card.dart';

/// O cartão grande "Seu objetivo" (E1.11, canvas `PropV1PerfilHome*`): o
/// caminho do objetivo, com miniatura, progresso e o botão. Só aparece com
/// [HomeState.goalPath].
class GoalCard extends StatelessWidget {
  const GoalCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final school = state.school;
    final endgame = state.endgameGoal;
    final train = state.trainGoal;
    final current = state.current;
    final next = state.next;
    if (state.goal == GoalPreference.learn && !state.boardControlsDone) {
      return _GoalHero(
        title: l10n.boardMoveMethod,
        line: l10n.boardControlsHint,
        progress: 0,
        progressText: l10n.boardControlsFirstStep,
        action: l10n.homeContinue,
        fen: GameRules.initial.fen,
        onPressed: () => context.push(Routes.boardControls),
      );
    }
    return switch (state.goalPath) {
      HomePath.learn when school != null => _GoalHero(
        title: l10n.homeSchool,
        line: l10n.homeGoalLearnLine(school.done + 1),
        progress: school.total == 0 ? 0 : school.done / school.total,
        progressText: l10n.homeGoalLessons(school.done, school.total),
        action: l10n.homeContinue,
        avatar: school.teacher,
        onPressed: () => school.ongoingLessonId == null
            ? context.go(Routes.school)
            : context.push(Routes.lessonScript(school.ongoingLessonId!)),
      ),
      HomePath.endgames when endgame != null => _GoalHero(
        title: endgame.lesson.title,
        line: l10n.homeGoalEndgamesLine(endgame.number, endgame.total),
        progress: endgame.total == 0 ? 0 : endgame.passed / endgame.total,
        progressText: l10n.homeGoalLessons(endgame.passed, endgame.total),
        action: l10n.homeContinue,
        fen: endgame.lesson.exerciseFen,
        avatar: endgame.lesson.exerciseFen == null
            ? endgame.lesson.teacher
            : null,
        onPressed: () => context.push(
          endgame.lesson.route,
          extra: endgame.lesson.exerciseFen,
        ),
      ),
      HomePath.train when train != null => _GoalHero(
        title: endgameName(l10n, train.suggestion.subcategory.key),
        line: l10n.homeGoalTrainLine,
        progress: train.suggestion.done / train.suggestion.total,
        progressText: l10n.homeGoalPositions(
          train.suggestion.done,
          train.suggestion.total,
        ),
        action: l10n.homeGoalTrain,
        fen: train.fen,
        onPressed: () => context.go(
          Routes.catalogCategory(
            train.suggestion.subcategory.category,
            subcategory: train.suggestion.subcategory.key,
          ),
        ),
      ),
      // Aprender a jogar sem a Escola: a Jornada.
      HomePath.journey when current != null => _GoalHero(
        title:
            state.character?.name ??
            opponentRefLabel(l10n, current.rung.opponent),
        line: next == null
            ? null
            : l10n.homeGoalJourneyLine(
                endgameName(l10n, next.position.subcategory),
              ),
        progress: current.rung.challenges.isEmpty
            ? 0
            : current.completed.length / current.rung.challenges.length,
        progressText: l10n.homeWhereProgress(
          current.completed.length,
          current.rung.challenges.length,
        ),
        action: l10n.homeContinue,
        avatar: state.character,
        onPressed:
            state.goal == GoalPreference.learn && !state.boardControlsDone
            ? () => context.push(Routes.boardControls)
            : next == null
            ? () => context.go(Routes.journey)
            : () => continueJourney(context, state),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _GoalHero extends StatelessWidget {
  const _GoalHero({
    required this.title,
    required this.line,
    required this.progress,
    required this.progressText,
    required this.action,
    required this.onPressed,
    this.avatar,
    this.fen,
  });

  final String title;
  final String? line;
  final double progress;
  final String progressText;
  final String action;
  final VoidCallback onPressed;

  /// A miniatura: o retrato à esquerda ou, sem ele, o tabuleiro à direita.
  final Character? avatar;
  final String? fen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final on = colors.onPrimary;
    final avatar = this.avatar;
    final fen = this.fen;
    final line = this.line;
    return Material(
      key: HomeKeys.goalCard,
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppShape.extraLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (avatar != null) ...[
                    CharacterAvatar(
                      character: avatar,
                      size: CharacterAvatar.speech,
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeGoalLabel.toUpperCase(),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: on.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        Text(
                          title,
                          key: HomeKeys.goalTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: on,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (line != null)
                          Text(
                            line,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: on.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (avatar == null && fen != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    PositionBoard(fen: fen, size: 72),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // A barra branca sobre o azul.
                        Theme(
                          data: theme.copyWith(
                            colorScheme: colors.copyWith(primary: on),
                          ),
                          child: AnimatedProgress(
                            value: progress,
                            backgroundColor: on.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          progressText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: on.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton.icon(
                    key: HomeKeys.goalAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: on,
                      foregroundColor: colors.primary,
                      minimumSize: const Size(0, kButtonHeightCompact),
                    ),
                    onPressed: onPressed,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(action),
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

/// "Continuar de onde parou", abaixo do objetivo: outra coisa em andamento
/// ([HomeState.resumePath]).
class ResumeCard extends StatelessWidget {
  const ResumeCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = state.current;
    final next = state.next;
    final endgame = state.endgame;
    switch (state.resumePath) {
      case HomePath.journey when current != null && next != null:
        final character = state.character;
        return _ResumeTile(
          title: l10n.homeGoalJourneyLine(
            endgameName(l10n, next.position.subcategory),
          ),
          line: l10n.homeResumeJourneyLine(
            character?.name ?? opponentRefLabel(l10n, current.rung.opponent),
          ),
          leading: character == null
              ? PositionBoard(fen: next.position.fen, size: 64)
              : CharacterAvatar(
                  character: character,
                  size: CharacterAvatar.tour,
                ),
          onTap: () => continueJourney(context, state),
        );
      case HomePath.endgames when endgame != null:
        final fen = endgame.exerciseFen;
        final teacher = endgame.teacher;
        return _ResumeTile(
          title: endgame.title,
          line: l10n.homeResumeEndgameLine(endgame.where(l10n)),
          leading: fen != null
              ? PositionBoard(fen: fen, size: 64)
              : teacher == null
              ? null
              : CharacterAvatar(character: teacher, size: CharacterAvatar.tour),
          onTap: () => context.push(endgame.route, extra: fen),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _ResumeTile extends StatelessWidget {
  const _ResumeTile({
    required this.title,
    required this.line,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final String line;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final leading = this.leading;
    return Card(
      key: HomeKeys.resumeCard,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeResumeLabel.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        title,
                        key: HomeKeys.resumeTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
