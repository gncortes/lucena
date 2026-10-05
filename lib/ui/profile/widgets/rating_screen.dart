import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/pace.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/opponent/opponent_ui.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/widgets/character_avatar.dart';
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
    final log = state.log;
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
                // Todas as partidas, de qualquer modo, da mais recente para a
                // mais antiga: a lista segue enquanto houver partida.
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 4),
                  child: Row(
                    children: [
                      Text(
                        l10n.statsGamesTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (log.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${log.length}',
                            key: RatingKeys.gamesCount,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (log.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 40,
                          color: colors.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.statsGamesEmpty,
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
                  for (final (index, game) in log.indexed) ...[
                    if (index > 0)
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: colors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    _GameRow(
                      index: index,
                      game: game,
                      characters: state.characters,
                    ),
                  ],
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

/// Uma partida do histórico, no formato do chess.com: o ritmo, o retrato e o
/// nome do adversário, o final jogado e a data, e o resultado; nas que
/// contaram para o rating, quanto ele mudou.
class _GameRow extends StatelessWidget {
  const _GameRow({
    required this.index,
    required this.game,
    required this.characters,
  });

  final int index;
  final LoggedGame game;
  final List<Character> characters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final attempt = game.attempt;
    final date = DateFormat.MMMd(locale)
        .add_Hm()
        .format(attempt.playedAt.toLocal());
    final time = attempt.userTime;
    final paceIcon = switch (time == null ? null : PaceCategory.of(time)) {
      null => Icons.timer_off_outlined,
      PaceCategory.bullet => Icons.bolt,
      PaceCategory.blitz => Icons.local_fire_department_outlined,
      PaceCategory.rapid => Icons.timer_outlined,
      PaceCategory.classical => Icons.hourglass_bottom,
    };
    final character = switch (attempt.opponent) {
      OpponentKind.stockfish => Character.stockfish,
      OpponentKind.maia => characters.forLevel(attempt.opponentLevel),
      OpponentKind.twoPlayers => null,
    };
    final level = attempt.opponent == OpponentKind.maia
        ? attempt.opponentLevel
        : null;
    final (resultColor, resultIcon, resultLabel) = switch (attempt.outcome) {
      AttemptOutcome.win => (
        ChangeColors.of(context, up: true),
        Icons.add_rounded,
        l10n.attemptWin,
      ),
      AttemptOutcome.draw => (
        colors.outline,
        Icons.drag_handle_rounded,
        l10n.attemptDraw,
      ),
      AttemptOutcome.loss => (
        ChangeColors.of(context, up: false),
        Icons.remove_rounded,
        l10n.attemptLoss,
      ),
    };
    final rated = game.rated;
    final change = rated?.change;
    // O final jogado, pelo id da posição (`categoria.subcategoria.número`).
    final parts = attempt.positionId.split('.');
    final endgame = parts.length > 1 ? endgameName(l10n, parts[1]) : null;
    return Padding(
      key: RatingKeys.entry(index),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            paceIcon,
            color: colors.primary,
            semanticLabel: time == null
                ? l10n.challengeNoClock
                : paceLabel(l10n, time),
          ),
          const SizedBox(width: 12),
          if (character != null)
            CharacterAvatar(character: character, size: 44)
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.person_outline, color: colors.outline),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            character?.name ??
                            attempt.opponent.label(l10n, level: level),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (level != null && character != null)
                        TextSpan(
                          text: '  ($level)',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                  key: RatingKeys.entryOpponent(index),
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [?endgame, date].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            key: RatingKeys.entryResult(index),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: resultColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              resultIcon,
              size: 18,
              color: colors.surface,
              semanticLabel: resultLabel,
            ),
          ),
          // O rating depois da partida e quanto ela o mudou, nas que contaram.
          SizedBox(
            width: 64,
            child: rated == null
                ? null
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${rated.entry.rating.rounded}',
                        key: RatingKeys.entryRating(index),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (change != null)
                        Text(
                          signedChange(change),
                          key: RatingKeys.entryChange(index),
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: change == 0
                                ? colors.onSurfaceVariant
                                : ChangeColors.of(context, up: change > 0),
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
