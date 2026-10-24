import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/race_rules.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/endgame_pieces.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../../settings/view_models/settings_cubit.dart';

/// O nome de cada objetivo.
String raceGoalLabel(AppLocalizations l10n, RaceGoal goal) => switch (goal) {
  RaceGoal.win => l10n.raceGoalWin,
  RaceGoal.defend => l10n.raceGoalDefend,
  RaceGoal.both => l10n.raceGoalBoth,
};

/// O resumo do filtro na abertura: "Ganhar · Todos os finais" ou "Ganhar ·
/// 12 tipos de final" (só os tipos que o banco tem para o objetivo).
String raceFilterSummary(
  AppLocalizations l10n,
  List<RaceProblem> bank,
  RaceFilter filter,
) {
  final types = [
    for (final group in RaceRules.types(bank, filter.goal).values)
      for (final type in group) type.subcategory,
  ];
  final selected = types.where((key) => !filter.excluded.contains(key)).length;
  return l10n.raceFilterSummary(
    raceGoalLabel(l10n, filter.goal),
    selected == types.length
        ? l10n.raceFilterAllEndings
        : l10n.raceFilterTypeCount(selected),
  );
}

/// Os filtros da Corrida em tela cheia: o objetivo (Ganhar, Defender, os
/// dois) e os tipos de final por categoria, cada categoria abre e fecha e
/// tem a caixa de marcar todos. O X fecha sem mudar; "Aplicar" devolve o
/// filtro. Só aparecem os tipos que o banco tem para o objetivo.
class RaceFilterScreen extends StatefulWidget {
  const RaceFilterScreen({
    required this.problems,
    required this.filter,
    super.key,
  });

  final List<RaceProblem> problems;
  final RaceFilter filter;

  @override
  State<RaceFilterScreen> createState() => _RaceFilterScreenState();
}

class _RaceFilterScreenState extends State<RaceFilterScreen> {
  late RaceFilter _filter = widget.filter;
  final _open = <String>{};

  void _set(RaceFilter filter) => setState(() => _filter = filter);

  void _toggle(Iterable<String> keys, {required bool selected}) => _set(
    _filter.copyWith(
      excluded: selected
          ? {..._filter.excluded}.difference(keys.toSet())
          : {..._filter.excluded, ...keys},
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final pieces = context.select(
      (SettingsCubit cubit) =>
          (cubit.state?.board ?? const BoardSettings()).pieces.assets,
    );
    final groups = RaceRules.types(widget.problems, _filter.goal);
    final any = RaceRules.count(widget.problems, _filter) > 0;
    return Scaffold(
      key: RaceKeys.filterScreen,
      appBar: LucenaAppBar(
        leading: IconButton(
          key: RaceKeys.filterClose,
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonLabel,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(l10n.raceFilters),
        actions: [
          TextButton(
            key: RaceKeys.filterClear,
            onPressed: _filter == const RaceFilter()
                ? null
                : () => _set(const RaceFilter()),
            child: Text(l10n.raceFilterClear),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: scrollPadding(
                context,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
              ),
              children: [
                SectionTitle(l10n.raceGoal, inset: 0),
                SegmentedButton<RaceGoal>(
                  key: RaceKeys.goal,
                  showSelectedIcon: false,
                  segments: [
                    for (final goal in RaceGoal.values)
                      ButtonSegment(
                        value: goal,
                        label: OneLine(
                          raceGoalLabel(l10n, goal),
                          key: RaceKeys.goalOption(goal),
                        ),
                      ),
                  ],
                  selected: {_filter.goal},
                  onSelectionChanged: (selection) =>
                      _set(_filter.copyWith(goal: selection.single)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.raceGoalDefendHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SectionTitle(l10n.raceWhichEndings, inset: 0),
                for (final MapEntry(key: category, value: types)
                    in groups.entries)
                  _Category(
                    name: categoryName(l10n, category),
                    category: category,
                    types: types,
                    excluded: _filter.excluded,
                    open: _open.contains(category),
                    pieces: pieces,
                    onExpand: () => setState(
                      () => _open.contains(category)
                          ? _open.remove(category)
                          : _open.add(category),
                    ),
                    onToggle: _toggle,
                  ),
              ],
            ),
          ),
          ActionsFooter(
            note: any
                ? null
                : Text(
                    l10n.raceFilterNone,
                    key: RaceKeys.filterNone,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
            children: [
              FilledButton.icon(
                key: RaceKeys.filterApply,
                icon: const Icon(Icons.check),
                label: Text(l10n.raceFilterApply),
                onPressed: any
                    ? () => Navigator.of(context).pop(_filter)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uma categoria: o cabeçalho (abre e fecha, "x de y" e a caixa que marca
/// ou desmarca todos) e, aberta, um tipo de final por linha.
class _Category extends StatelessWidget {
  const _Category({
    required this.name,
    required this.category,
    required this.types,
    required this.excluded,
    required this.open,
    required this.pieces,
    required this.onExpand,
    required this.onToggle,
  });

  final String name;
  final String category;
  final List<RaceEndgameType> types;
  final Set<String> excluded;
  final bool open;
  final PieceAssets pieces;
  final VoidCallback onExpand;
  final void Function(Iterable<String> keys, {required bool selected}) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final keys = [for (final type in types) type.subcategory];
    final selected = keys.where((key) => !excluded.contains(key)).length;
    final all = selected == keys.length;
    final mineSlots = types
        .map((type) => EndgamePieces.slots(type.mine))
        .reduce((a, b) => a > b ? a : b);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        children: [
          InkWell(
            key: RaceKeys.filterCategory(category),
            onTap: onExpand,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                spacing: AppSpacing.md,
                children: [
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    size: AppIconSize.standard,
                    color: colors.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    l10n.raceFilterCategoryCount(selected, keys.length),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Semantics(
                    label: name,
                    child: Checkbox(
                      key: RaceKeys.filterCategoryCheck(category),
                      tristate: true,
                      value: all ? true : (selected == 0 ? false : null),
                      onChanged: (_) => onToggle(keys, selected: !all),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            for (final type in types)
              _Type(
                type: type,
                selected: !excluded.contains(type.subcategory),
                mineSlots: mineSlots,
                pieces: pieces,
                onToggle: onToggle,
              ),
        ],
      ),
    );
  }
}

/// Um tipo de final: só as peças na tela e o nome para o leitor de tela; a
/// linha inteira marca e desmarca.
class _Type extends StatelessWidget {
  const _Type({
    required this.type,
    required this.selected,
    required this.mineSlots,
    required this.pieces,
    required this.onToggle,
  });

  final RaceEndgameType type;
  final bool selected;
  final int mineSlots;
  final PieceAssets pieces;
  final void Function(Iterable<String> keys, {required bool selected}) onToggle;

  @override
  Widget build(BuildContext context) {
    void toggle() => onToggle([type.subcategory], selected: !selected);
    return MergeSemantics(
      child: Semantics(
        label: endgameName(context.l10n, type.subcategory),
        child: InkWell(
          onTap: toggle,
          child: SizedBox(
            height: 52,
            child: Row(
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: EndgamePieces(
                        mine: type.mine,
                        theirs: type.theirs,
                        pieces: pieces,
                        mineSlots: mineSlots,
                      ),
                    ),
                  ),
                ),
                Checkbox(
                  key: RaceKeys.filterType(type.subcategory),
                  value: selected,
                  onChanged: (_) => toggle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
