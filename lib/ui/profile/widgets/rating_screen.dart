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
import '../../core/review/move_quality_ui.dart';
import '../../core/widgets/character_avatar.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/rating_chart.dart';
import '../../core/widgets/rating_value.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/skeleton.dart';
import '../view_models/rating_cubit.dart';
import 'rating_parts.dart';
import 'stats_row.dart';
import '../../core/widgets/one_line.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';

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
      appBar: AppBar(
        title: Text(l10n.profileEndgameRating),
        actions: [
          // A explicação do rating, antes um parágrafo fixo no fim da tela.
          IconButton(
            key: RatingKeys.help,
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.ratingHelp,
            onPressed: () => showRatingHelp(context),
          ),
        ],
      ),
      body: current == null
          // Carregando: o cartão e a lista em esqueleto, no lugar certo.
          ? ListView(
              key: RatingKeys.loading,
              padding: scrollPadding(context),
              children: const [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.screen),
                  child: SkeletonBlock(height: 220, radius: AppShape.large),
                ),
                SkeletonList(),
              ],
            )
          : ListView(
              // Espaço no fim: a última partida rola até sair da barra do
              // sistema.
              padding: scrollPadding(context, bottom: 48),
              children: [
                // Como no chess.com: o rating e o gráfico num cartão, com o
                // período embaixo; depois os números e os resultados.
                _RatingCard(state: state),
                if (state.numbers case final numbers?) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screen,
                      AppSpacing.betweenCards,
                      AppSpacing.screen,
                      0,
                    ),
                    child: StatsRow(numbers: numbers),
                  ),
                  if (state.allGames.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.betweenCards,
                        AppSpacing.screen,
                        0,
                      ),
                      child: _Results(games: state.allGames.values),
                    ),
                ],
                // Todas as partidas, de qualquer modo, da mais recente para a
                // mais antiga: a lista segue enquanto houver partida. O
                // cabeçalho diz o que é e quantas são.
                Padding(
                  key: RatingKeys.historyHeader,
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.screen,
                    AppSpacing.xxl,
                    AppSpacing.screen,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.statsGamesTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            if (log.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(
                                    AppShape.full,
                                  ),
                                ),
                                child: Text(
                                  '${log.length}',
                                  key: RatingKeys.gamesCount,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colors.onPrimaryContainer,
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
                          maxLines: 1,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                if (log.isEmpty)
                  EmptyState(
                    icon: Icons.history_rounded,
                    message: l10n.statsGamesEmpty,
                    messageKey: RatingKeys.emptyHistory,
                    actionLabel: l10n.emptyPlayNow,
                    actionKey: RatingKeys.emptyHistoryAction,
                    onAction: () => context.go(Routes.catalog),
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
                      highlighted: game.id == state.highlighted,
                    ),
                  ],
              ],
            ),
    );
  }
}

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

  // O painel do filtro: os períodos, o escolhido marcado. Tocar escolhe e
  // fecha.
  Future<void> _choosePeriod(BuildContext context) async {
    final l10n = context.l10n;
    final chosen = await showModalBottomSheet<RatingPeriod>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                0,
                AppSpacing.screen,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.ratingPeriodTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final period in RatingPeriod.values)
              ListTile(
                key: RatingKeys.period(period.name),
                title: Text(_label(l10n, period)),
                selected: period == _period,
                trailing: period == _period
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(period),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) setState(() => _period = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final state = widget.state;
    final current = state.current!;
    final now = state.now ?? state.history.lastOrNull?.at ?? DateTime.utc(2000);
    final entries = _period.entries(state.history, now);
    final change = _period.change(state.history, now);
    final highest = highestRating(state.history);
    // A partida em destaque, se ela está no período escolhido.
    final highlightedGame = state.highlighted;
    final highlighted = highlightedGame == null
        ? -1
        : entries.indexWhere((entry) => entry.gameId == highlightedGame);
    final locale = Localizations.localeOf(context).toString();
    return Card(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        0,
      ),
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
                          // A variação do período escolhido.
                          change: change,
                          large: true,
                          valueKey: RatingKeys.value,
                          changeKey: RatingKeys.delta,
                        ),
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
                // Na ponta direita do cartão, o número do outro lado.
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
              const SizedBox(height: 12),
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
              const SizedBox(height: AppSpacing.md),
              // O período num botão de filtro: abre o painel com as opções.
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  key: RatingKeys.periods,
                  icon: const Icon(Icons.filter_list_rounded),
                  label: Text(_label(l10n, _period), maxLines: 1),
                  onPressed: () => _choosePeriod(context),
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
      ('win', wins, l10n.attemptWin, ChangeColors.of(context, up: true)),
      ('draw', draws, l10n.attemptDraw, colors.outline),
      ('loss', losses, l10n.attemptLoss, ChangeColors.of(context, up: false)),
    ];
    return Container(
      key: RatingKeys.results,
      padding: const EdgeInsets.all(AppSpacing.insideCard),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // O título e o total na mesma linha, logo acima da barra.
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OneLine(
                    l10n.ratingResultsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$total',
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Uma barra só, cada parte na proporção do seu resultado.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppShape.full),
            child: SizedBox(
              key: RatingKeys.resultsBar,
              height: 12,
              // Esticado: sem filho, a cor sozinha teria altura zero.
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (_, count, _, color) in parts)
                    if (count > 0)
                      Expanded(
                        flex: count,
                        child: ColoredBox(color: color),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // A legenda presa às pontas da barra: vitórias à esquerda (onde a
          // barra começa), derrotas à direita e empates no meio.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, (name, count, label, color)) in parts.indexed)
                Expanded(
                  key: RatingKeys.resultsPart(name),
                  child: Column(
                    crossAxisAlignment: switch (index) {
                      0 => CrossAxisAlignment.start,
                      1 => CrossAxisAlignment.center,
                      _ => CrossAxisAlignment.end,
                    },
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '$count',
                            maxLines: 1,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      OneLine(
                        '$label · ${(100 * count / total).round()}%',
                        style: theme.textTheme.labelMedium?.copyWith(
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
    this.highlighted = false,
  });

  final int index;
  final LoggedGame game;
  final List<Character> characters;

  /// A partida que a conclusão abriu: o fundo tingido.
  final bool highlighted;

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
    final row = InkWell(
      key: RatingKeys.entry(index),
      // Na volta, a partida pode ter ganhado a revisão (e a precisão).
      onTap: () => context.push(Routes.game(game.id)).then((_) {
        if (context.mounted) context.read<RatingCubit>().load();
      }),
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
                  borderRadius: BorderRadius.circular(AppShape.small),
                ),
                child: Icon(Icons.smart_toy_outlined, color: colors.outline),
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
            // A precisão do jogador, nas partidas já revisadas (como no
            // histórico do chess.com).
            if (game.accuracy case final accuracy?) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.reviewAccuracy,
                child: Container(
                  key: RatingKeys.entryAccuracy(index),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppShape.small),
                  ),
                  child: Text(
                    formatAccuracy(
                      accuracy,
                      Localizations.localeOf(context).toString(),
                    ),
                    semanticsLabel:
                        '${l10n.reviewAccuracy} ${formatAccuracy(accuracy, Localizations.localeOf(context).toString())}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Container(
              key: RatingKeys.entryResult(index),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: resultColor,
                borderRadius: BorderRadius.circular(AppShape.small),
              ),
              child: Icon(
                resultIcon,
                size: 18,
                color: colors.surface,
                semanticLabel: resultLabel,
              ),
            ),
            // Nas que contaram: quanto a partida mudou o rating e como ele
            // ficou.
            SizedBox(
              width: 64,
              child: rated == null
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (change != null)
                          Text(
                            signedChange(change),
                            key: RatingKeys.entryChange(index),
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: change == 0
                                  ? colors.onSurfaceVariant
                                  : ChangeColors.of(context, up: change > 0),
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        Text(
                          '${rated.entry.rating.rounded}',
                          key: RatingKeys.entryRating(index),
                          style:
                              (change == null
                                      ? theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        )
                                      : theme.textTheme.labelMedium?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ))
                                  ?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
    if (!highlighted) return row;
    return Material(
      key: RatingKeys.entryHighlighted,
      color: colors.primaryContainer.withValues(alpha: 0.5),
      child: row,
    );
  }
}
