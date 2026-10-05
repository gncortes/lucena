import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../domain/models/attempt.dart';
import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/rating_chart.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/rating_cubit.dart';
import 'stats_row.dart';

/// Os detalhes do rating de finais: o número, o gráfico com a escolha do
/// período e as partidas que mexeram nele, da mais recente para a mais antiga.
class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final state = context.watch<RatingCubit>().state;
    final current = state.current;
    final games = state.games;
    return Scaffold(
      key: RatingKeys.screen,
      appBar: AppBar(title: Text(l10n.profileEndgameRating)),
      body: current == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: scrollPadding(context),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [
                          RatingValue(
                            rating: current.rounded,
                            change: state.lastChange,
                            large: true,
                            valueKey: RatingKeys.value,
                            changeKey: RatingKeys.delta,
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
                        key: RatingKeys.games,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.numbers case final numbers?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: StatsRow(numbers: numbers),
                  ),
                if (state.history.length > 1)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    color: colors.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                      child: _Chart(
                        ratings: [
                          for (final entry in state.history)
                            entry.rating.rating,
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    l10n.profileRatingHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 4),
                  child: Text(
                    l10n.ratingHistory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (games.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 40,
                          color: colors.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.ratingHistoryEmpty,
                          key: RatingKeys.emptyHistory,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final (index, game) in games.indexed)
                    _GameTile(index: index, game: game),
              ],
            ),
    );
  }
}

/// O gráfico com a escolha do período: as últimas 10, as últimas 30 ou todas
/// as partidas.
class _Chart extends StatefulWidget {
  const _Chart({required this.ratings});

  final List<double> ratings;

  @override
  State<_Chart> createState() => _ChartState();
}

class _ChartState extends State<_Chart> {
  // Quantas partidas o gráfico mostra. Nulo: todas.
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
        RatingChart(key: RatingKeys.chart, ratings: ratings),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final period in _periods)
                ChoiceChip(
                  key: RatingKeys.period(period),
                  label: Text(
                    period == null
                        ? l10n.profileRatingPeriodAll
                        : l10n.profileRatingPeriodGames(period),
                  ),
                  selected: _games == period,
                  onSelected: (_) => setState(() => _games = period),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Uma partida que contou: o resultado, contra quem e quando, o rating depois
/// dela e quanto ela mudou.
class _GameTile extends StatelessWidget {
  const _GameTile({required this.index, required this.game});

  final int index;
  final RatedGame game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.yMMMd(locale)
        .add_Hm()
        .format(game.entry.at.toLocal());
    final attempt = game.attempt;
    final change = game.change;
    final (color, icon, title) = switch (attempt?.outcome) {
      AttemptOutcome.win => (
        ChangeColors.of(context, up: true),
        Icons.emoji_events_rounded,
        l10n.attemptWin,
      ),
      AttemptOutcome.draw => (
        colors.onSurfaceVariant,
        Icons.handshake_rounded,
        l10n.attemptDraw,
      ),
      AttemptOutcome.loss => (
        ChangeColors.of(context, up: false),
        Icons.flag_rounded,
        l10n.attemptLoss,
      ),
      // Sem a partida, só o ponto do rating e a data.
      null => (colors.onSurfaceVariant, Icons.show_chart_rounded, date),
    };
    return Card(
      key: RatingKeys.entry(index),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (attempt != null)
                    Text(
                      l10n.attemptDetails(
                        attempt.opponent.label(
                          l10n,
                          level: attempt.opponentLevel,
                        ),
                        date,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${game.entry.rating.rounded}',
                  key: RatingKeys.entryRating(index),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (change != null)
                  Text(
                    signedChange(change),
                    key: RatingKeys.entryChange(index),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: change == 0
                          ? colors.onSurfaceVariant
                          : ChangeColors.of(context, up: change > 0),
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
