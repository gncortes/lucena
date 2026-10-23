import 'package:flutter/material.dart';

import '../../core/theme/app_chip.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/rating_level.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../profile/widgets/rating_level_ui.dart';
import '../view_models/endgames_cubit.dart';
import '../../core/widgets/sheet_header.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';

/// Como cada tipo de final aparece nas telas.
extension EndgameKindUi on EndgameKind {
  String label(AppLocalizations l10n) => switch (this) {
    EndgameKind.pawn => l10n.endgamesKindPawn,
    EndgameKind.queen => l10n.endgamesKindQueen,
    EndgameKind.rook => l10n.endgamesKindRook,
    EndgameKind.bishop => l10n.endgamesKindBishop,
    EndgameKind.knight => l10n.endgamesKindKnight,
    EndgameKind.minor => l10n.endgamesKindMinor,
  };

  String get code => 'kind.$name';
}

/// Como cada situação de aula aparece no filtro.
extension EndgameLessonStatusUi on EndgameLessonStatus {
  String label(AppLocalizations l10n) => switch (this) {
    EndgameLessonStatus.open => l10n.endgamesStatusOpen,
    EndgameLessonStatus.started => l10n.endgamesStatusStarted,
    EndgameLessonStatus.passed => l10n.endgamesStatusPassed,
  };

  String get code => 'status.$name';
}

String _levelCode(RatingLevel level) => 'level.${EnumName(level).name}';

/// O botão de filtro da barra, com o número de filtros ativos.
class EndgamesFilterButton extends StatelessWidget {
  const EndgamesFilterButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<EndgamesCubit, int>(
      (cubit) => cubit.state.filter.count,
    );
    return IconButton(
      key: EndgamesKeys.filtersButton,
      tooltip: context.l10n.endgamesFilters,
      isSelected: count > 0,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(context.l10n.endgamesFiltersCount(count)),
        child: const Icon(Icons.filter_list),
      ),
      onPressed: () => showEndgamesFilterSheet(context),
    );
  }
}

/// Abre o modal dos filtros. Cada toque já vale (e fica gravado); o botão
/// de baixo fecha mostrando quantas aulas sobraram.
Future<void> showEndgamesFilterSheet(BuildContext context) {
  final cubit = context.read<EndgamesCubit>();
  return showLucenaSheet<void>(
    context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const SafeArea(top: false, child: _FilterSheet()),
    ),
  );
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<EndgamesCubit, EndgamesState>(
      builder: (context, state) {
        final cubit = context.read<EndgamesCubit>();
        final filter = state.filter;
        final levels = state.availableLevels;
        final shown = state.filteredLessons.length;
        return Column(
          key: EndgamesKeys.filtersSheet,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: l10n.endgamesFilters,
              trailing: filter.isEmpty
                  ? null
                  : TextButton(
                      key: EndgamesKeys.filtersSheetClear,
                      onPressed: cubit.clearFilter,
                      child: Text(l10n.endgamesFiltersClear),
                    ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  if (levels.isNotEmpty) ...[
                    _Heading(l10n.endgamesFilterOrder),
                    _Options(
                      children: [
                        for (final sort in EndgameSort.values)
                          ChoiceChip(
                            materialTapTargetSize: AppChip.tapTarget,
                            visualDensity: AppChip.density,
                            key: EndgamesKeys.filterOption('sort.${sort.name}'),
                            label: Text(switch (sort) {
                              EndgameSort.trail => l10n.endgamesSortTrail,
                              EndgameSort.easiest => l10n.endgamesSortEasiest,
                            }),
                            selected: filter.sort == sort,
                            onSelected: (_) => cubit.setSort(sort),
                          ),
                      ],
                    ),
                    _Heading(l10n.endgamesFilterLevel),
                    _Options(
                      children: [
                        for (final level in levels)
                          FilterChip(
                            materialTapTargetSize: AppChip.tapTarget,
                            visualDensity: AppChip.density,
                            key: EndgamesKeys.filterOption(_levelCode(level)),
                            label: Text(level.name(l10n)),
                            selected: filter.levels.contains(level),
                            onSelected: (_) => cubit.toggleLevel(level),
                          ),
                      ],
                    ),
                  ],
                  _Heading(l10n.endgamesFilterKind),
                  _Options(
                    children: [
                      for (final kind in state.availableKinds)
                        FilterChip(
                          materialTapTargetSize: AppChip.tapTarget,
                          visualDensity: AppChip.density,
                          key: EndgamesKeys.filterOption(kind.code),
                          label: Text(kind.label(l10n)),
                          selected: filter.kinds.contains(kind),
                          onSelected: (_) => cubit.toggleKind(kind),
                        ),
                    ],
                  ),
                  _Heading(l10n.endgamesFilterStatus),
                  _Options(
                    children: [
                      for (final status in EndgameLessonStatus.values)
                        FilterChip(
                          materialTapTargetSize: AppChip.tapTarget,
                          visualDensity: AppChip.density,
                          key: EndgamesKeys.filterOption(status.code),
                          label: Text(status.label(l10n)),
                          selected: filter.statuses.contains(status),
                          onSelected: (_) => cubit.toggleStatus(status),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ActionsFooter(
              margin: AppSpacing.xl,
              children: [
                FilledButton(
                  key: EndgamesKeys.filtersApply,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.endgamesFiltersShow(shown)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: children,
  );
}

/// Os filtros ativos, como chips com X, e o "Limpar".
class EndgamesActiveFilters extends StatelessWidget {
  const EndgamesActiveFilters({super.key, required this.state});

  final EndgamesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<EndgamesCubit>();
    final filter = state.filter;
    Widget chip(String code, String label, VoidCallback onDeleted) => InputChip(
      materialTapTargetSize: AppChip.tapTarget,
      visualDensity: AppChip.density,
      key: EndgamesKeys.filterChip(code),
      label: Text(label),
      onPressed: () => showEndgamesFilterSheet(context),
      onDeleted: onDeleted,
    );
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (filter.sort == EndgameSort.easiest)
            chip(
              'sort.easiest',
              l10n.endgamesSortEasiest,
              () => cubit.setSort(EndgameSort.trail),
            ),
          for (final level in RatingLevel.values)
            if (filter.levels.contains(level))
              chip(
                _levelCode(level),
                level.name(l10n),
                () => cubit.toggleLevel(level),
              ),
          for (final kind in EndgameKind.values)
            if (filter.kinds.contains(kind))
              chip(kind.code, kind.label(l10n), () => cubit.toggleKind(kind)),
          for (final status in EndgameLessonStatus.values)
            if (filter.statuses.contains(status))
              chip(
                status.code,
                status.label(l10n),
                () => cubit.toggleStatus(status),
              ),
          TextButton(
            key: EndgamesKeys.filtersClear,
            onPressed: cubit.clearFilter,
            child: Text(l10n.endgamesFiltersClear),
          ),
        ],
      ),
    );
  }
}

/// Nenhuma aula com os filtros ativos.
class EndgamesFiltersEmpty extends StatelessWidget {
  const EndgamesFiltersEmpty({super.key});

  @override
  Widget build(BuildContext context) => EmptyState(
    key: EndgamesKeys.filtersEmpty,
    style: EmptyStateStyle.filters,
    message: context.l10n.endgamesFiltersEmpty,
    actionLabel: context.l10n.endgamesFiltersClearAll,
    actionKey: EndgamesKeys.filtersEmptyClear,
    onAction: context.read<EndgamesCubit>().clearFilter,
  );
}
