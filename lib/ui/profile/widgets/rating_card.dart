import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/rating_sparkline.dart';
import '../../core/widgets/rating_value.dart';
import '../view_models/rating_cubit.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/filled_segments.dart';
import 'rating_parts.dart';

/// O rating de finais: o número, se ainda é provisório, a curva das partidas e
/// o que ele mede.
class RatingCard extends StatelessWidget {
  const RatingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final state = context.watch<RatingCubit>().state;
    final current = state.current;
    if (current == null) return const SizedBox.shrink();
    return Card(
      key: ProfileKeys.ratingCard,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // O título e o ⓘ com a explicação (antes um parágrafo fixo no fim
            // do cartão), como na tela de rating.
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.profileEndgameRating,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: ProfileKeys.ratingHelp,
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.ratingHelp,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showRatingHelp(context),
                ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              children: [
                // O número grande e, ao lado, a variação da última partida.
                RatingValue(
                  rating: current.rounded,
                  change: state.lastChange,
                  large: true,
                  valueKey: ProfileKeys.ratingValue,
                  changeKey: ProfileKeys.ratingDelta,
                ),
                if (state.provisional)
                  Chip(
                    label: Text(l10n.profileRatingProvisional),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
              ],
            ),
            Text(
              state.history.isEmpty
                  ? l10n.profileRatingStart
                  : l10n.profileRatingGames(state.history.length),
              key: ProfileKeys.ratingGames,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (state.history.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              _Chart(
                ratings: [
                  for (final entry in state.history) entry.rating.rating,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A curva com a escolha do período: as últimas 10, as últimas 30 ou todas
/// as partidas.
class _Chart extends StatefulWidget {
  const _Chart({required this.ratings});

  final List<double> ratings;

  @override
  State<_Chart> createState() => _ChartState();
}

class _ChartState extends State<_Chart> {
  // Quantas partidas a curva mostra. Nulo: todas.
  int? _games;

  static const _periods = [10, 30, null];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final games = _games;
    final ratings = games == null || widget.ratings.length <= games
        ? widget.ratings
        : widget.ratings.sublist(widget.ratings.length - games);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RatingSparkline(key: ProfileKeys.ratingChart, ratings: ratings),
        const SizedBox(height: AppSpacing.md),
        // O mesmo seletor da tela de rating: o escolhido preenchido.
        FilledSegments<int?>(
          values: _periods,
          selected: _games,
          label: (period) => period == null
              ? l10n.profileRatingPeriodAll
              : l10n.profileRatingPeriodGames(period),
          labelKey: ProfileKeys.ratingPeriod,
          onChanged: (period) => setState(() => _games = period),
        ),
      ],
    );
  }
}
