import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/history_filter.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/use_cases/history_games.dart';
import '../../../domain/use_cases/rating_period.dart';
import '../../../routing/routes.dart';
import '../../core/keys/history_keys.dart';
import '../../core/keys/rating_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/container_navigation.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/skeleton.dart';
import '../view_models/history_cubit.dart';
import 'game_row.dart';
import 'history_filters.dart';
import 'history_labels.dart';
import 'rating_card.dart';

/// A aba Partidas: o cartão do rating com a curva, os filtros, o placar e as
/// partidas que contaram, por mês.
class HistoryGamesTab extends StatelessWidget {
  const HistoryGamesTab({this.gameDestinationBuilder, super.key});

  /// O destino dos detalhes de uma partida (o da rota canônica).
  final Widget Function(BuildContext, int)? gameDestinationBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HistoryCubit>().state;
    if (!state.loaded) return const HistoryLoading();
    // Espaço no fim: a última partida rola até sair da barra do sistema.
    final padding = scrollPadding(context, bottom: 48);
    // Nada ainda no rating: só o convite.
    if (state.history.isEmpty) {
      return ListView(
        key: RatingKeys.screen,
        // 32 acima do vazio, como no canvas.
        padding: padding + const EdgeInsets.only(top: AppSpacing.xxl),
        children: [_empty(context)],
      );
    }
    final cubit = context.read<HistoryCubit>();
    final filter = state.gamesFilter;
    final games = state.filteredGames;
    final filteredOut = games.isEmpty && !filter.isEmpty;
    final score = HistoryGames.score(games);
    return ListView(
      key: RatingKeys.screen,
      padding: padding,
      children: [
        HistoryFilterBar(
          chips: [
            HistoryChipData(
              name: 'period',
              label: filter.period == RatingPeriod.all
                  ? l10n.historyFilterPeriod
                  : HistoryLabels.period(l10n, filter.period),
              active: filter.period != RatingPeriod.all,
            ),
            HistoryChipData(
              name: 'result',
              label: switch (filter.result) {
                null => l10n.historyFilterResult,
                AttemptOutcome.win => l10n.attemptWin,
                AttemptOutcome.draw => l10n.attemptDraw,
                AttemptOutcome.loss => l10n.attemptLoss,
              },
              active: filter.result != null,
            ),
            HistoryChipData(
              name: 'pace',
              label: filter.pace == null
                  ? l10n.historyFilterPace
                  : HistoryLabels.gamePace(l10n, filter.pace!),
              active: filter.pace != null,
            ),
          ],
          onOpen: () => _openSheet(context, state),
        ),
        if (filteredOut)
          HistoryFilteredEmpty(
            message: l10n.historyEmptyFilteredGames,
            onClear: () => cubit.applyGamesFilter(const GamesHistoryFilter()),
          )
        else ...[
          HistoryRatingCard(state: state),
          if (games.isNotEmpty) ...[
            HistoryScore(
              items: [
                (score.wins, l10n.historyStatWins(score.wins)),
                (score.draws, l10n.historyStatDraws(score.draws)),
                (score.losses, l10n.historyStatLosses(score.losses)),
              ],
            ),
            ..._months(context, state, games),
          ] else
            _empty(context),
        ],
      ],
    );
  }

  // O convite para a primeira partida.
  Widget _empty(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: HistoryKeys.empty,
      child: EmptyState(
        icon: Icons.history_rounded,
        message: l10n.ratingHistoryEmpty,
        messageKey: RatingKeys.emptyHistory,
        actionLabel: l10n.emptyFirstEndgame,
        style: EmptyStateStyle.primary,
        actionIcon: Icons.play_arrow_rounded,
        actionKey: RatingKeys.emptyHistoryAction,
        onAction: () {
          final router = GoRouter.of(context);
          ContainerNavigation.leave(context, () => router.go(Routes.catalog));
        },
      ),
    );
  }

  // As partidas por mês, a mais recente primeiro.
  List<Widget> _months(
    BuildContext context,
    HistoryState state,
    List<HistoryGame> games,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.yMMMM(locale);
    final children = <Widget>[];
    String? current;
    var months = 0;
    for (final (index, game) in games.indexed) {
      final label = HistoryLabels.capitalize(
        format.format(game.attempt.playedAt.toLocal()),
      );
      if (label != current) {
        current = label;
        children.add(
          Padding(
            key: HistoryKeys.month(months++),
            // Cabeçalho de grupo: 16 16 8 16 (artboard).
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colors.primary,
              ),
            ),
          ),
        );
      } else {
        children.add(Divider());
      }
      children.add(
        HistoryGameRow(
          key: ValueKey(game.id),
          destinationBuilder: gameDestinationBuilder,
          index: index,
          game: game,
          characters: state.characters,
          highlighted: game.id == state.highlighted,
        ),
      );
    }
    return children;
  }

  Future<void> _openSheet(BuildContext context, HistoryState state) async {
    final l10n = context.l10n;
    final cubit = context.read<HistoryCubit>();
    final now = state.now ?? DateTime.utc(2000);
    final chosen = await showHistoryFilterSheet(
      context,
      groups: [
        HistoryFilterGroup(
          name: 'period',
          title: l10n.historyFilterPeriod,
          fallback: RatingPeriod.all.name,
          options: [
            for (final period in RatingPeriod.values)
              HistoryOption(period.name, HistoryLabels.period(l10n, period)),
          ],
        ),
        HistoryFilterGroup(
          name: 'result',
          title: l10n.historyFilterResult,
          options: [
            HistoryOption(AttemptOutcome.win.code, l10n.attemptWin),
            HistoryOption(AttemptOutcome.draw.code, l10n.attemptDraw),
            HistoryOption(AttemptOutcome.loss.code, l10n.attemptLoss),
          ],
        ),
        HistoryFilterGroup(
          name: 'pace',
          title: l10n.historyFilterPace,
          options: [
            for (final pace in PaceCategory.values)
              HistoryOption(pace.code, HistoryLabels.gamePace(l10n, pace.code)),
            HistoryOption(GamesHistoryFilter.noClock, l10n.challengeNoClock),
          ],
        ),
      ],
      initial: state.gamesFilter.selection,
      count: (draft) => HistoryGames.filter(
        state.games,
        GamesHistoryFilter.fromSelection(draft),
        now,
      ).length,
      applyLabel: l10n.historyFiltersShowGames,
    );
    if (chosen != null) {
      await cubit.applyGamesFilter(GamesHistoryFilter.fromSelection(chosen));
    }
  }
}

/// O esqueleto enquanto o Histórico é lido: o cartão e a lista.
class HistoryLoading extends StatelessWidget {
  const HistoryLoading({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    key: HistoryKeys.loading,
    padding: scrollPadding(context),
    children: const [
      Padding(
        padding: EdgeInsets.all(AppSpacing.screen),
        child: SkeletonBlock(height: 220, radius: AppShape.large),
      ),
      SkeletonList(),
    ],
  );
}
