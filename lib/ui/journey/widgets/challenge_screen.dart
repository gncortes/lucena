import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/journey.dart';
import '../../../domain/models/pace.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/journey_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/attempt_history.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/position_board.dart';
import '../view_models/journey_cubit.dart';
import 'journey_ui.dart';
import '../../core/theme/app_shape.dart';

/// Um desafio: o tabuleiro grande, o objetivo e o ritmo em selos, o
/// adversário, as partidas já jogadas e o botão de jogar fixo embaixo.
class ChallengeScreen extends StatelessWidget {
  const ChallengeScreen({required this.rungId, super.key});

  /// O adversário (degrau) do desafio: o retrato dele chega voando da tela
  /// de antes.
  final String rungId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<JourneyCubit>().state;
    final challenge = state.challenge;
    return Scaffold(
      key: JourneyKeys.challengeScreen,
      appBar: AppBar(
        title: Text(
          challenge == null
              ? l10n.journeyChallengeTitle
              : endgameName(l10n, challenge.position.subcategory),
        ),
      ),
      bottomNavigationBar: challenge == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  key: JourneyKeys.play,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.journeyPlay),
                  onPressed: () async {
                    if (!await playChallenge(context, challenge)) return;
                    if (!context.mounted) return;
                    final uri = GoRouterState.of(context).pathParameters;
                    await context.read<JourneyCubit>().load(
                      rungId: uri['rung'],
                      positionId: uri['position'],
                    );
                  },
                ),
              ),
            ),
      body: challenge == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _BigBoard(challenge: challenge),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GoalChip(challenge: challenge),
                      _Chip(
                        icon: switch (challenge.time) {
                          final time? => paceIcon(PaceCategory.of(time)),
                          null => Icons.timer_off_outlined,
                        },
                        text: switch (challenge.time) {
                          final time? => l10n.speedrunTimeControl(
                            time.initial.inMinutes,
                            time.increment.inSeconds,
                          ),
                          null => l10n.challengeNoClock,
                        },
                      ),
                    ],
                  ),
                ),
                _OpponentCard(opponent: challenge.opponent, rungId: rungId),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
                  child: Text(
                    l10n.setupHistory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (state.attempts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_esports_outlined,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.challengeHistoryInvite,
                          key: JourneyKeys.emptyHistory,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  AttemptHistory(
                    attempts: state.attempts,
                    monthKey: JourneyKeys.month,
                    attemptKey: JourneyKeys.attempt,
                  ),
              ],
            ),
    );
  }
}

/// A posição na largura da tela, vista pelo lado que joga. Ela chega voando
/// do tabuleiro pequeno da tela de antes (a do adversário ou a inicial).
class _BigBoard extends StatelessWidget {
  const _BigBoard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => PositionBoard(
        fen: challenge.position.fen,
        size: constraints.maxWidth,
        coordinates: true,
        radius: 0,
        heroTag: challengeBoardTag(challenge.id),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final style = GoalStyle.of(context, challenge.goal);
    return _Chip(
      icon: style.icon,
      text: goalLabel(context.l10n, challenge.goal),
      background: style.container,
      foreground: style.onContainer,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.text,
    this.background,
    this.foreground,
  });

  final IconData icon;
  final String text;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = this.foreground ?? colors.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? colors.secondaryContainer,
        borderRadius: BorderRadius.circular(AppShape.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Contra quem: o retrato, o nome, o nível e a frase do personagem.
class _OpponentCard extends StatelessWidget {
  const _OpponentCard({required this.opponent, required this.rungId});

  final OpponentRef opponent;
  final String rungId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final characters = context.select(
      (JourneyCubit cubit) => cubit.state.characters,
    );
    final character = opponentCharacter(characters, opponent);
    final language = Localizations.localeOf(context).languageCode;
    final tagline = character?.taglineIn(language) ?? '';
    return Card(
      key: JourneyKeys.opponentCard,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (character != null) ...[
              Hero(
                tag: opponentHeroTag(rungId),
                child: CharacterAvatar(character: character, size: 64),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.challengeOpponent,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    [
                      opponentName(l10n, characters, opponent),
                      if (opponent.level case final level?) '$level',
                    ].join(' · '),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (tagline.isNotEmpty)
                    Text(
                      '“$tagline”',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
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
