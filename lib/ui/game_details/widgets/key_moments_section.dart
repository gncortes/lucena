import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/key_moments.dart';
import '../../core/keys/game_details_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/review/move_quality_ui.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../view_models/game_details_cubit.dart';
import 'review_widgets.dart';

/// Os momentos decisivos da partida (canvas `CompMomentoChave`): até três
/// lances que mudaram o rumo, cada um com a qualidade, o melhor lance e a
/// avaliação antes e depois. Tocar no cartão leva o tabuleiro ao lance.
/// Quando o jogador não errou, a seção diz isso e, se foi vitória, mostra o
/// lance do adversário que decidiu.
class KeyMomentsSection extends StatelessWidget {
  const KeyMomentsSection({
    required this.state,
    required this.userIsWhite,
    super.key,
  });

  final GameDetailsState state;

  /// O lado do jogador; nulo em partida de dois jogadores.
  final bool? userIsWhite;

  @override
  Widget build(BuildContext context) {
    final review = state.review;
    final start = state.start;
    if (review == null || start == null || state.reviewing) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstIsWhite = start.turn != Side.black;
    final moments = KeyMoments.pick(review, firstIsWhite: firstIsWhite);
    final clean =
        userIsWhite != null &&
        KeyMoments.userMadeNoError(
          review,
          firstIsWhite: firstIsWhite,
          userIsWhite: userIsWhite!,
        );
    final won = state.outcome == AttemptOutcome.win;
    return Padding(
      key: GameDetailsKeys.moments,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.partidaMomentos, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (clean) ...[
            Row(
              key: GameDetailsKeys.noMistakes,
              children: [
                Icon(Icons.workspace_premium, color: colors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.partidaSemErro,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (won && moments.isNotEmpty)
              Text(
                l10n.partidaVitoriaDoAdversario,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
          ],
          if (moments.isEmpty && !clean)
            Text(
              l10n.partidaMomentosVazio,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          for (final moment in moments)
            _MomentCard(
              state: state,
              moment: moment,
              firstIsWhite: firstIsWhite,
            ),
        ],
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.state,
    required this.moment,
    required this.firstIsWhite,
  });

  final GameDetailsState state;
  final KeyMoment moment;
  final bool firstIsWhite;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final index = moment.index;
    final played = state.moves[index];
    final before = index == 0 ? state.start! : state.moves[index - 1].position;
    final number = before.turn == Side.white
        ? '${before.fullmoves}.'
        : '${before.fullmoves}...';
    final quality = moment.move.quality;
    final best = moment.move.best == null
        ? null
        : GameRules.sanLine(before, [moment.move.best!], max: 1).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppShape.medium),
        child: InkWell(
          key: GameDetailsKeys.moment(index),
          borderRadius: BorderRadius.circular(AppShape.medium),
          onTap: () => context.read<GameDetailsCubit>().select(index),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: quality.color,
                  child: Text(
                    quality.symbol,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.chessWhiteColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: SanText(
                              '$number ${played.san}',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            quality.label(l10n),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (best != null && best != played.san)
                        Text(
                          l10n.reviewBestWas(best),
                          style: theme.textTheme.bodyMedium,
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            formatScore(moment.move.before, locale),
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            Icons.trending_flat,
                            size: AppIconSize.button,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            formatScore(moment.move.after, locale),
                            style: theme.textTheme.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tabela "Lances por qualidade" (canvas `CompQualidades`): as seis
/// qualidades com a contagem de cada lado.
class QualityTable extends StatelessWidget {
  const QualityTable({
    required this.state,
    required this.leftName,
    required this.rightName,
    required this.leftIsWhite,
    super.key,
  });

  final GameDetailsState state;

  /// Os nomes das duas colunas e se a da esquerda é das brancas.
  final String leftName;
  final String rightName;
  final bool leftIsWhite;

  static const _rows = [
    MoveQuality.best,
    MoveQuality.excellent,
    MoveQuality.good,
    MoveQuality.inaccuracy,
    MoveQuality.mistake,
    MoveQuality.blunder,
  ];

  @override
  Widget build(BuildContext context) {
    final review = state.review;
    final start = state.start;
    if (review == null || start == null || state.reviewing) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final firstIsWhite = start.turn != Side.black;
    final left = KeyMoments.qualityTable(
      review,
      white: leftIsWhite,
      firstIsWhite: firstIsWhite,
    );
    final right = KeyMoments.qualityTable(
      review,
      white: !leftIsWhite,
      firstIsWhite: firstIsWhite,
    );
    Widget count(int value) => SizedBox(
      width: 64,
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleSmall?.copyWith(
          color: value == 0 ? colors.outline : colors.onSurface,
        ),
      ),
    );
    return Padding(
      key: GameDetailsKeys.qualityTable,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.partidaQualidades, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              SizedBox(
                width: 64,
                child: Text(
                  leftName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  rightName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
          for (final quality in _rows)
            Padding(
              key: GameDetailsKeys.qualityRow(quality.name),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: quality.color,
                    child: Text(
                      quality.symbol,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.chessWhiteColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      quality.label(l10n),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  count(left[quality]!),
                  count(right[quality]!),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
