import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_avatar.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/home_cubit.dart';

/// Onde o jogador está na Jornada, contra quem joga e o próximo passo, com o
/// rating ao lado.
class WhereCard extends StatelessWidget {
  const WhereCard({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final current = state.current;
    final next = state.next;
    final character = state.character;
    return Card(
      key: HomeKeys.whereCard,
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (character != null) ...[
                  CharacterAvatar(character: character, size: 48),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current == null
                            ? l10n.homeWhereDone
                            : l10n.homeWhereTitle(
                                opponentRefLabel(l10n, current.rung.opponent),
                              ),
                        key: HomeKeys.whereTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                      if (current != null)
                        Text(
                          l10n.homeWhereProgress(
                            current.completed.length,
                            current.rung.challenges.length,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                    ],
                  ),
                ),
                if (state.rating case final rating?)
                  Chip(
                    key: HomeKeys.rating,
                    avatar: const Icon(Icons.trending_up, size: 18),
                    label: Text(l10n.homeRating(rating)),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (current != null && next != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.homeWhereNext(
                        categoryName(l10n, next.position.category),
                        character?.name ??
                            opponentRefLabel(l10n, next.opponent),
                      ),
                      key: HomeKeys.whereNext,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSecondaryContainer,
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
