import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/position_board.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/home_cubit.dart';

/// "Continuar": o adversário atual da Jornada, o progresso contra ele e o
/// próximo desafio, com o tabuleiro em miniatura.
class WhereCard extends StatelessWidget {
  const WhereCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    if (state.school case final school?) return _SchoolCard(school: school);
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
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
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
                    onPressed: () => context.go(
                      Routes.journeyChallenge(
                        current.rung.id,
                        next.position.id,
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
                    borderRadius: BorderRadius.circular(3),
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
              onPressed: () => context.go(Routes.school),
              child: Text(l10n.homeContinue),
            ),
          ],
        ),
      ),
    );
  }
}
