import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/star_challenge.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../endgames/widgets/stars_row.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/star_challenge_cubit.dart';
import 'star_challenge_ui.dart';

/// A lista dos desafios das estrelas: uma peça por cartão, três níveis em
/// cada, com a melhor marca.
class StarChallengesScreen extends StatelessWidget {
  const StarChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: StarChallengeKeys.listScreen,
      appBar: LucenaAppBar(title: Text(l10n.starChallengesTitle)),
      body: BlocBuilder<StarChallengesCubit, StarChallengesState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          return ListView(
            padding: scrollPadding(
              context,
              left: 16,
              top: 8,
              right: 16,
              bottom: 32,
            ),
            children: [
              Text(
                l10n.starChallengesIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final piece in ChallengePiece.values) ...[
                _PieceCard(piece: piece, progress: state.progress),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.piece, required this.progress});

  final ChallengePiece piece;
  final StarChallengeProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _PieceTile(piece: piece),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pieceName(l10n, piece), style: context.cardTitle),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: AppIconSize.small,
                            color: StarsRow.color,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.starChallengePointsTotal(
                              [
                                for (final level in ChallengeLevel.values)
                                  progress.bestOf(piece, level) ?? 0,
                              ].fold(0, (sum, each) => sum + each),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                for (final (index, level) in ChallengeLevel.values.indexed) ...[
                  if (index > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _LevelButton(
                      piece: piece,
                      level: level,
                      best: progress.bestOf(piece, level),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.piece,
    required this.level,
    required this.best,
  });

  final ChallengePiece piece;
  final ChallengeLevel level;
  final int? best;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final best = this.best;
    final played = best != null;
    return Material(
      color: played
          ? colors.secondaryContainer
          : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppShape.medium),
      child: InkWell(
        key: StarChallengeKeys.challenge(piece.name, level.name),
        borderRadius: BorderRadius.circular(AppShape.medium),
        onTap: () => context.push(Routes.starChallenge(piece.name, level.name)),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              Text(
                levelName(l10n, level),
                style: theme.textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              // O nível vale tantas estrelas quanto a dificuldade; acendem
              // pela melhor marca.
              StarsRow(
                total: level.stars,
                earned: best == null ? 0 : earnedOf(level, best),
                size: 16,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                best == null
                    ? l10n.starChallengeNotPlayed
                    : l10n.starChallengeBest(best),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A peça do conjunto escolhido pelo jogador, numa casa do tabuleiro.
class _PieceTile extends StatelessWidget {
  const _PieceTile({required this.piece});

  final ChallengePiece piece;

  @override
  Widget build(BuildContext context) {
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final settings = boardSettings.chessground;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppShape.medium),
      child: ColoredBox(
        color: settings.colorScheme.lightSquare,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          // A imagem direto do conjunto: o PieceWidget depende do cache que
          // só o tabuleiro enche.
          child: Image(
            image: settings
                .pieceAssets[Piece(color: Side.white, role: piece.role).kind]!,
            width: 48,
            height: 48,
          ),
        ),
      ),
    );
  }
}
