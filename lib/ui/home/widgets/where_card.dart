import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/home_layout.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/position_board.dart';
import '../../journey/view_models/journey_cubit.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/home_cubit.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/theme/app_shape.dart';

/// "Continuar": o adversário atual da Jornada, o progresso contra ele e o
/// próximo desafio, com o tabuleiro em miniatura.
class WhereCard extends StatelessWidget {
  const WhereCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    // Só aponta para um caminho em destaque na tela inicial.
    switch (state.continuePath) {
      case null:
        return const SizedBox.shrink();
      case HomePath.endgames || HomePath.forYou when state.endgame != null:
        return _EndgameCard(endgame: state.endgame!);
      case HomePath.learn when state.school != null:
        return _SchoolCard(school: state.school!);
      default:
        return _journey(context);
    }
  }

  Widget _journey(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final current = state.current;
    final next = state.next;
    final character = state.character;
    final onColor = colors.onSecondaryContainer;
    final done = current?.completed.length ?? 0;
    final total = current?.rung.challenges.length ?? 0;
    return Card(
      key: HomeKeys.whereCard,
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (character != null) ...[
                  // O retrato voa até o cartão do adversário, na tela do
                  // desafio.
                  if (current != null)
                    Hero(
                      tag: opponentHeroTag(current.rung.id),
                      child: CharacterAvatar(character: character, size: 56),
                    )
                  else
                    CharacterAvatar(character: character, size: 56),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (current != null)
                        Text(
                          l10n.journeyNowFacing,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: onColor,
                          ),
                        ),
                      Text(
                        current == null
                            ? l10n.homeWhereDone
                            : character?.name ??
                                  opponentRefLabel(l10n, current.rung.opponent),
                        key: HomeKeys.whereTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: onColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppShape.small),
                child: AnimatedProgress(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 8,
                  backgroundColor: colors.surface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.homeWhereProgress(done, total),
                style: theme.textTheme.bodySmall?.copyWith(color: onColor),
              ),
            ],
            if (current != null && next != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  PositionBoard(
                    key: HomeKeys.whereBoard,
                    fen: next.position.fen,
                    size: 64,
                    radius: 4,
                    heroTag: challengeBoardTag(next.id),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      endgameName(l10n, next.position.subcategory),
                      key: HomeKeys.whereNext,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: HomeKeys.whereContinue,
                    // A tela do desafio abre por cima desta, já com o
                    // desafio pronto: o tabuleiro e o retrato voam até ela.
                    onPressed: () => context.push(
                      Routes.journeyChallenge(
                        current.rung.id,
                        next.position.id,
                      ),
                      extra: JourneyState(
                        challenge: next,
                        characters: [?character],
                      ),
                    ),
                    child: Text(l10n.homeContinue),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Para o iniciante: as aulas do Viktor vêm antes da Jornada.
class _SchoolCard extends StatelessWidget {
  const _SchoolCard({required this.school});

  final SchoolSummary school;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final teacher = school.teacher;
    return Card(
      key: HomeKeys.schoolCard,
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Row(
          children: [
            if (teacher != null) ...[
              CharacterAvatar(character: teacher, size: 48),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeSchool,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: school.total == 0 ? 0 : school.done / school.total,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(AppShape.small),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.schoolLessonsDone(school.done, school.total),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: HomeKeys.schoolContinue,
              onPressed: () => school.ongoingLessonId == null
                  ? context.go(Routes.school)
                  : context.push(Routes.lesson(school.ongoingLessonId!)),
              child: Text(l10n.homeContinue),
            ),
          ],
        ),
      ),
    );
  }
}

/// A aula de final em andamento: o título, onde parou e "continuar", que
/// volta direto ao exercício ou à lição aberta.
class _EndgameCard extends StatelessWidget {
  const _EndgameCard({required this.endgame});

  final EndgameSummary endgame;

  String _where(AppLocalizations l10n) {
    final exercise = endgame.exerciseNumber;
    final step = endgame.step;
    if (exercise != null) {
      return l10n.exerciseTitle(exercise, endgame.exerciseCount!);
    }
    final part = endgame.partNumber;
    if (part != null) return l10n.homeEndgamePart(part, endgame.partCount!);
    if (step != null) return l10n.lessonStep(step, endgame.stepCount!);
    return l10n.endgameScore(endgame.score, endgame.maxScore);
  }

  String get _route {
    final exerciseId = endgame.openExerciseId;
    if (exerciseId != null) {
      return Routes.endgameExercise(endgame.lessonId, exerciseId);
    }
    if (endgame.lessonOpen) {
      return Routes.endgameLessonSteps(endgame.lessonId, part: endgame.partId);
    }
    return Routes.endgameLesson(endgame.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final teacher = endgame.teacher;
    return Card(
      key: HomeKeys.endgameCard,
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Row(
          children: [
            if (teacher != null) ...[
              CharacterAvatar(character: teacher, size: 48),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.homeEndgames,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    endgame.title,
                    key: HomeKeys.endgameTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _where(l10n),
                    key: HomeKeys.endgameWhere,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              key: HomeKeys.endgameContinue,
              onPressed: () => context.push(_route),
              child: Text(l10n.homeContinue),
            ),
          ],
        ),
      ),
    );
  }
}
