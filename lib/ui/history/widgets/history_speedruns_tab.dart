import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character.dart';
import '../../../domain/models/history_filter.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/speedrun_history_rows.dart';
import '../../../routing/routes.dart';
import '../../core/keys/history_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/pace/pace_ui.dart';
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
        // 32 acima do vazio, como no canvas.
        padding: padding + const EdgeInsets.only(top: AppSpacing.xxl),
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
    final rows = state.rows(_tab);
    final score = SpeedrunHistoryRows.score(rows);
    return ListView(
      padding: padding,
      children: [
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
          for (final (group, level) in SpeedrunCategory.values.indexed)
            if (_inLevel(rows, level) case final inLevel
                when inLevel.isNotEmpty) ...[
              _GroupHeader(
                key: HistoryKeys.group(group),
                level: level,
                count: inLevel.length,
                marathon: marathon,
              ),
              _GroupCard(
                rows: inLevel,
                characters: state.characters,
                onOpen: (row) => _open(context, row),
              ),
            ],
        ],
      ],
    );
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

  /// Abre a folha de filtros da aba (o ícone da barra de cima chama).
  Future<void> openFilter(BuildContext context) async {
    final state = context.read<HistoryCubit>().state;
    final all = marathon ? state.marathons : state.classic;
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

/// As linhas de um nível, com a posição de cada uma na lista toda.
List<(int, SpeedrunHistoryRow)> _inLevel(
  List<SpeedrunHistoryRow> rows,
  SpeedrunCategory level,
) => [
  for (final (index, row) in rows.indexed)
    if (row.category == level) (index, row),
];

/// O cabeçalho de um nível: o nome e quantos speedruns (ou maratonas) há nele.
// reuso: SectionTitle não serve porque o cabeçalho de grupo do Histórico é
// primary com 16 16 8 16 (artboard), não cinza.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.level,
    required this.count,
    required this.marathon,
    super.key,
  });

  final SpeedrunCategory level;
  final int count;
  final bool marathon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final title = HistoryLabels.level(l10n, level);
    return Padding(
      // Cabeçalho de grupo: 16 16 8 16 (artboard).
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Text(
        marathon
            ? l10n.historyGroupMarathons(title, count)
            : l10n.historyGroupSpeedruns(title, count),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// O cartão com as linhas de um nível.
class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.rows,
    required this.characters,
    required this.onOpen,
  });

  final List<(int, SpeedrunHistoryRow)> rows;
  final List<Character> characters;
  final ValueChanged<SpeedrunHistoryRow> onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (position, (index, row)) in rows.indexed) ...[
            if (position > 0) const Divider(),
            SpeedrunHistoryRowTile(
              row: row,
              index: index,
              characters: characters,
              onTap: () => onOpen(row),
            ),
          ],
        ],
      ),
    );
  }
}
