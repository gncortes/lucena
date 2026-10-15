import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../domain/use_cases/history_games.dart';
import '../../../domain/use_cases/rating_period.dart';
import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/rating_chart.dart';
import '../../core/widgets/rating_value.dart';
import '../view_models/history_cubit.dart';

/// O rating, quanto ele mudou no período, o mais alto e o gráfico. O período
/// vem do filtro da aba (`semPeriodo` no canvas): o cartão não tem chip dele.
/// A curva é o histórico inteiro do período, com os bônus de speedrun.
class HistoryRatingCard extends StatelessWidget {
  const HistoryRatingCard({required this.state, super.key});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final current = state.current!;
    final period = state.gamesFilter.period;
    final now = state.now ?? state.history.lastOrNull?.at ?? DateTime.utc(2000);
    final entries = period.entries(state.history, now);
    final change = period.change(state.history, now);
    final highest = highestRating(state.history);
    final counted = HistoryGames.counted(state.history);
    // A partida em destaque, se ela está no período escolhido.
    final highlightedGame = state.highlighted;
    final highlighted = highlightedGame == null
        ? -1
        : entries.indexWhere((entry) => entry.gameId == highlightedGame);
    final locale = Localizations.localeOf(context).toString();
    return Padding(
      // Padding 16 16 0 (artboard PropV2HistoricoAbaPartidasP360).
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.screen,
        AppSpacing.screen,
        AppSpacing.screen,
        0,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.insideCard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Numa linha só: em tela estreita, o número diminui.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: RatingValue(
                            rating: current.rounded,
                            change: change,
                            large: true,
                            animateOnce: true,
                            valueKey: RatingKeys.value,
                            changeKey: RatingKeys.delta,
                          ),
                        ),
                        Text(
                          state.history.isEmpty
                              ? l10n.profileRatingStart
                              : l10n.profileRatingGames(counted),
                          key: RatingKeys.games,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // O mais alto, como no chess.com.
                  if (highest != null && state.history.length > 1) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      key: RatingKeys.highest,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.ratingHighest,
                          maxLines: 1,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${highest.rating.rounded}',
                          maxLines: 1,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          DateFormat.yMMMd(locale).format(highest.at.toLocal()),
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (state.history.length > 1) ...[
                const SizedBox(height: AppSpacing.md),
                AnimatedSwitcher(
                  duration: AppMotion.of(context).state,
                  child: entries.length > 1
                      ? RatingChart(
                          key: RatingKeys.chart,
                          highlighted: highlighted < 0 ? null : highlighted,
                          ratings: [
                            for (final entry in entries) entry.rating.rating,
                          ],
                        )
                      : SizedBox(
                          key: RatingKeys.chartEmpty,
                          height: 200,
                          child: Center(
                            child: Text(
                              l10n.ratingPeriodEmpty,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
