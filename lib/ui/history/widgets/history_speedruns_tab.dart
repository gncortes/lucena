import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/history_filter.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/speedrun_history_rows.dart';
import '../../../routing/routes.dart';
import '../../core/keys/history_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/history_cubit.dart';
import 'history_filters.dart';
import 'history_games_tab.dart';
import 'history_labels.dart';
import 'speedrun_history_row.dart';

/// As abas Clássico e Maratona: uma linha por speedrun (final e ritmo), por
/// nível, sem gráfico. [marathon] escolhe a aba.
class HistorySpeedrunsTab extends StatelessWidget {
  const HistorySpeedrunsTab({required this.marathon, super.key});

  final bool marathon;

  HistoryTab get _tab => marathon ? HistoryTab.marathon : HistoryTab.classic;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<HistoryCubit>().state;
    if (!state.loaded) return const HistoryLoading();
    final all = marathon ? state.marathons : state.classic;
    // Espaço no fim: a última linha rola até sair da barra do sistema.
    final padding = scrollPadding(context, bottom: 48);
    if (all.isEmpty) {
      return ListView(
        padding: padding,
        children: [
          KeyedSubtree(
            key: HistoryKeys.empty,
            child: EmptyState(
              icon: marathon ? Icons.all_inclusive : Icons.timer,
              message: marathon
                  ? l10n.historyEmptyMarathons
                  : l10n.historyEmptySpeedruns,
            ),
          ),
        ],
      );
    }
    final filter = marathon ? state.marathonFilter : state.classicFilter;
    final rows = state.rows(_tab);
    final score = SpeedrunHistoryRows.score(rows);
    return ListView(
      padding: padding,
      children: [
        HistoryFilterBar(
          chips: [
            HistoryChipData(
              name: 'level',
              label: filter.level == null
                  ? l10n.historyFilterLevel
                  : HistoryLabels.level(l10n, filter.level!),
              active: filter.level != null,
            ),
            HistoryChipData(
              name: 'pace',
              label: filter.pace == null
                  ? l10n.historyFilterPace
                  : filter.pace!.label(l10n),
              active: filter.pace != null,
            ),
          ],
          onOpen: () => _openSheet(context, state, all),
        ),
        if (rows.isEmpty)
          HistoryFilteredEmpty(
            message: marathon
                ? l10n.historyEmptyFilteredMarathons
                : l10n.historyEmptyFilteredSpeedruns,
            onClear: () => _apply(context, const SpeedrunHistoryFilter()),
          )
        else ...[
          HistoryScore(
            items: [
              (score.attempts, l10n.historyStatAttempts(score.attempts)),
              (
                score.finished,
                marathon
                    ? l10n.historyStatFinishedMarathons(score.finished)
                    : l10n.historyStatFinishedSpeedruns(score.finished),
              ),
              (score.newRecords, l10n.historyStatNewRecords(score.newRecords)),
            ],
          ),
          ..._groups(context, state, rows),
        ],
      ],
    );
  }

  List<Widget> _groups(
    BuildContext context,
    HistoryState state,
    List<SpeedrunHistoryRow> rows,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final children = <Widget>[];
    for (final (group, level) in SpeedrunCategory.values.indexed) {
      final inLevel = [
        for (final (index, row) in rows.indexed)
          if (row.category == level) (index, row),
      ];
      if (inLevel.isEmpty) continue;
      final title = HistoryLabels.level(l10n, level);
      children.add(
        Padding(
          key: HistoryKeys.group(group),
          // Cabeçalho de grupo: 16 16 8 16 (artboard).
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            marathon
                ? l10n.historyGroupMarathons(title, inLevel.length)
                : l10n.historyGroupSpeedruns(title, inLevel.length),
            style: theme.textTheme.titleSmall?.copyWith(color: colors.primary),
          ),
        ),
      );
      children.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppShape.large),
          ),
          child: Column(
            children: [
              for (final (position, (index, row)) in inLevel.indexed) ...[
                if (position > 0)
                  Divider(height: 1, color: colors.outlineVariant),
                SpeedrunHistoryRowTile(
                  row: row,
                  index: index,
                  characters: state.characters,
                  onTap: () => _open(context, row),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return children;
  }

  // O histórico do speedrun (a Maratona usa o mesmo até a T67f); ao voltar,
  // lê tudo de novo.
  Future<void> _open(BuildContext context, SpeedrunHistoryRow row) async {
    final cubit = context.read<HistoryCubit>();
    await context.push<void>(Routes.speedrunHistory(row.speedrun.id));
    if (!cubit.isClosed) await cubit.load();
  }

  Future<void> _apply(BuildContext context, SpeedrunHistoryFilter filter) {
    final cubit = context.read<HistoryCubit>();
    return marathon
        ? cubit.applyMarathonFilter(filter)
        : cubit.applyClassicFilter(filter);
  }

  Future<void> _openSheet(
    BuildContext context,
    HistoryState state,
    List<SpeedrunHistoryRow> all,
  ) async {
    final l10n = context.l10n;
    final chosen = await showHistoryFilterSheet(
      context,
      groups: [
        HistoryFilterGroup(
          name: 'level',
          title: l10n.historyFilterLevel,
          options: [
            for (final level in SpeedrunCategory.values)
              HistoryOption(level.name, HistoryLabels.level(l10n, level)),
          ],
        ),
        HistoryFilterGroup(
          name: 'pace',
          title: l10n.historyFilterPace,
          options: [
            for (final pace in SpeedrunPaces.groups.keys)
              HistoryOption(pace.code, pace.label(l10n)),
          ],
        ),
      ],
      initial:
          (marathon ? state.marathonFilter : state.classicFilter).selection,
      count: (draft) => SpeedrunHistoryRows.filter(
        all,
        SpeedrunHistoryFilter.fromSelection(draft),
      ).length,
      applyLabel: marathon
          ? l10n.historyFiltersShowMarathons
          : l10n.historyFiltersShowSpeedruns,
    );
    if (chosen != null && context.mounted) {
      await _apply(context, SpeedrunHistoryFilter.fromSelection(chosen));
    }
  }
}
