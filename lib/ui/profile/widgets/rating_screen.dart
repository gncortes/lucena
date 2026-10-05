import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../data/repositories/characters/character_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/use_cases/rating_period.dart';
import '../../../routing/routes.dart';
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
                // Como no chess.com: o rating e o gráfico num cartão, com o
                // período embaixo; depois os números e os resultados.
                _RatingCard(state: state),
                if (state.numbers case final numbers?) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: StatsRow(numbers: numbers),
                  ),
                  if (state.allGames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _Results(games: state.allGames.values),
                    ),
                ],
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
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 28, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.statsGamesTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            if (log.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${log.length}',
                                  key: RatingKeys.gamesCount,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // O que a coluna da direita mostra.
                      if (log.any((game) => game.rated != null))
                        Text(
                          l10n.reportRatingLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
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
                        color: colors.outlineVariant.withValues(alpha: 0.4),
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
/// O rating, quanto ele mudou no período, o mais alto e o gráfico, com a
/// escolha do período (7, 30 e 90 dias, um ano ou tudo).
class _RatingCard extends StatefulWidget {
  const _RatingCard({required this.state});

  final RatingState state;

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  RatingPeriod _period = RatingPeriod.all;

  String _label(AppLocalizations l10n, RatingPeriod period) => switch (period) {
    RatingPeriod.all => l10n.profileRatingPeriodAll,
    RatingPeriod.year => l10n.ratingPeriodYear,
    _ => l10n.ratingPeriodDays(period.days!),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final state = widget.state;
    final current = state.current!;
    final now = state.now ?? DateTime.now().toUtc();
    final entries = _period.entries(state.history, now);
    final change = _period.change(state.history, now);
    final highest = highestRating(state.history);
    final locale = Localizations.localeOf(context).toString();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          RatingValue(
                            rating: current.rounded,
                            // A variação do período escolhido.
                            change: change,
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
                // O mais alto, como no chess.com.
                if (highest != null && state.history.length > 1)
                  Column(
                    key: RatingKeys.highest,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.ratingHighest,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${highest.rating.rounded}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd(locale).format(highest.at.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (state.history.length > 1) ...[
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                child: entries.length > 1
                    ? RatingChart(
                        key: RatingKeys.chart,
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
              const SizedBox(height: 8),
              // Os períodos numa fileira que rola para o lado em tela
              // estreita.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final period in RatingPeriod.values) ...[
                      if (period != RatingPeriod.values.first)
                        const SizedBox(width: 6),
                      ChoiceChip(
                        key: RatingKeys.period(period.name),
                        label: Text(_label(l10n, period)),
                        showCheckmark: false,
                        selected: _period == period,
                        onSelected: (_) => setState(() => _period = period),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Vitórias, empates e derrotas numa barra só, com a contagem e a
/// porcentagem de cada um, como no chess.com.
class _Results extends StatelessWidget {
  const _Results({required this.games});

  final Iterable<Attempt> games;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    var wins = 0, draws = 0, losses = 0;
    for (final game in games) {
      switch (game.outcome) {
        case AttemptOutcome.win:
          wins++;
        case AttemptOutcome.draw:
          draws++;
        case AttemptOutcome.loss:
          losses++;
      }
    }
    final total = wins + draws + losses;
    final parts = [
      (wins, l10n.attemptWin, ChangeColors.of(context, up: true)),
      (draws, l10n.attemptDraw, colors.outline),
      (losses, l10n.attemptLoss, ChangeColors.of(context, up: false)),
    ];
    return Container(
      key: RatingKeys.results,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final (count, _, color) in parts)
                    if (count > 0)
                      Expanded(
                        flex: count,
                        child: ColoredBox(color: color),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (count, label, color) in parts)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '$label · ${(100 * count / total).round()}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uma partida do histórico, enxuta como no chess.com: o ícone do ritmo, o
/// retrato pequeno, o nome e o nível do adversário, a marca do resultado e
/// quanto o rating mudou. Tocar abre os detalhes.
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
    final attempt = game.attempt;
    final time = attempt.userTime;
    final category = time == null ? null : PaceCategory.of(time);
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
    return InkWell(
      key: RatingKeys.entry(index),
      onTap: () => context.push(Routes.game(game.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // O ritmo pelo ícone de sempre: raio, chama, relógio.
            Icon(
              category == null ? Icons.timer_off_outlined : paceIcon(category),
              size: 24,
              color: ChangeColors.of(context, up: true),
              semanticLabel: time == null
                  ? l10n.challengeNoClock
                  : paceLabel(l10n, time),
            ),
            const SizedBox(width: 14),
            if (character != null)
              CharacterAvatar(character: character, size: 36)
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(Icons.person_outline, color: colors.outline),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
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
                        text: ' ($level)',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
                key: RatingKeys.entryOpponent(index),
                style: theme.textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              key: RatingKeys.entryResult(index),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                resultIcon,
                size: 18,
                color: colors.surface,
                semanticLabel: resultLabel,
              ),
            ),
            // Quanto a partida mudou o rating, nas que contaram.
            SizedBox(
              width: 56,
              child: change == null
                  ? null
                  : Text(
                      signedChange(change),
                      key: RatingKeys.entryChange(index),
                      textAlign: TextAlign.end,
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: change == 0
                            ? colors.onSurfaceVariant
                            : ChangeColors.of(context, up: change > 0),
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
