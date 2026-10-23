import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/keys/history_keys.dart';
import '../../core/l10n/l10n.dart';

/// Um chip da faixa de filtros: [name] é o grupo (`period`, `result`...),
/// [label] o que ele diz e [active] se há um valor escolhido.
class HistoryChipData {
  const HistoryChipData({
    required this.name,
    required this.label,
    required this.active,
  });

  final String name;
  final String label;
  final bool active;
}

/// A faixa de filtros no alto de cada aba: o botão `tune` e um chip por
/// dimensão. Qualquer um abre a mesma folha ([onOpen]).
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    required this.chips,
    required this.onOpen,
    super.key,
  });

  final List<HistoryChipData> chips;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Início 16, topo 12, fim 16 (artboard PropV2HistoricoAbaPartidasP360).
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          // O botão tem 32 dp no desenho; o alvo de toque é de 48.
          Tooltip(
            message: context.l10n.historyFiltersAll,
            child: InkResponse(
              key: HistoryKeys.filterChip('all'),
              onTap: onOpen,
              radius: 24,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 40, minHeight: 48),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppShape.small),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Icon(
                      Icons.tune,
                      size: AppIconSize.button,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
          for (final chip in chips) ...[
            const SizedBox(width: AppSpacing.sm),
            _MenuChip(chip: chip, onTap: onOpen),
          ],
        ],
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({required this.chip, required this.onTap});

  final HistoryChipData chip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      materialTapTargetSize: AppChip.tapTarget,
      visualDensity: AppChip.density,
      key: HistoryKeys.filterChip(chip.name),
      label: Text(chip.label, maxLines: 1),
      selected: chip.active,
      onSelected: (_) => onTap(),
      // A seta é o ícone de apagar do chip: abre a mesma folha.
      deleteIcon: const Icon(Icons.arrow_drop_down),
      deleteButtonTooltipMessage: '',
      onDeleted: onTap,
    );
  }
}

/// Uma opção de um grupo da folha: o [value] (da key) e o [label].
class HistoryOption {
  const HistoryOption(this.value, this.label);

  final String value;
  final String label;
}

/// Um grupo da folha de filtros: uma escolha só, ou nenhuma. Com [fallback]
/// o grupo volta a ele em vez de ficar vazio (o período): tocar na marcada
/// não desmarca.
class HistoryFilterGroup {
  const HistoryFilterGroup({
    required this.name,
    required this.title,
    required this.options,
    this.fallback,
  });

  final String name;
  final String title;
  final List<HistoryOption> options;

  /// O valor do padrão, que o Limpar volta a escolher e que tocar na marcada
  /// não tira. Nulo: o grupo pode ficar sem valor.
  final String? fallback;
}

/// Abre a folha de filtros. Mostra o rascunho começando em [initial]
/// (grupo -> valor) e devolve o escolhido ao aplicar. [apply] diz o texto do
/// botão para as escolhas do rascunho, e [count] quantos resultados elas dão
/// (o botão fica desabilitado em 0). Fechar sem aplicar devolve nulo.
Future<Map<String, String?>?> showHistoryFilterSheet(
  BuildContext context, {
  required List<HistoryFilterGroup> groups,
  required Map<String, String?> initial,
  required int Function(Map<String, String?> draft) count,
  required String Function(int count) applyLabel,
}) => showLucenaSheet<Map<String, String?>>(
  context,
  builder: (_) => _FilterSheet(
    groups: groups,
    initial: initial,
    count: count,
    applyLabel: applyLabel,
  ),
);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.groups,
    required this.initial,
    required this.count,
    required this.applyLabel,
  });

  final List<HistoryFilterGroup> groups;
  final Map<String, String?> initial;
  final int Function(Map<String, String?>) count;
  final String Function(int) applyLabel;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Map<String, String?> _draft = {...widget.initial};

  bool get _dirty =>
      widget.groups.any((group) => _draft[group.name] != group.fallback);

  void _toggle(HistoryFilterGroup group, String value) => setState(() {
    final selected = _draft[group.name] == value;
    _draft = {..._draft, group.name: selected ? group.fallback : value};
  });

  void _clear() => setState(() {
    _draft = {for (final group in widget.groups) group.name: group.fallback};
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shown = widget.count(_draft);
    return SafeArea(
      top: false,
      child: Column(
        key: HistoryKeys.filterSheet,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(
            title: l10n.historyFilters,
            trailing: TextButton(
              key: HistoryKeys.filterClear,
              onPressed: _dirty ? _clear : null,
              child: Text(l10n.historyFiltersClear),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              children: [
                for (final group in widget.groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.sm,
                    ),
                    child: Text(
                      group.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final option in group.options)
                        FilterChip(
                          materialTapTargetSize: AppChip.tapTarget,
                          visualDensity: AppChip.density,
                          key: HistoryKeys.filterOption(
                            group.name,
                            option.value,
                          ),
                          label: Text(option.label),
                          selected: _draft[group.name] == option.value,
                          onSelected: (_) => _toggle(group, option.value),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          ActionsFooter(
            margin: AppSpacing.xl,
            children: [
              FilledButton(
                key: HistoryKeys.filterApply,
                onPressed: shown == 0
                    ? null
                    : () => Navigator.of(context).pop(_draft),
                child: Text(
                  widget.applyLabel(shown),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A aba sem resultado do filtro: fica a faixa de chips e, no lugar da
/// lista, o aviso com o botão que limpa tudo.
class HistoryFilteredEmpty extends StatelessWidget {
  const HistoryFilteredEmpty({
    required this.message,
    required this.onClear,
    super.key,
  });

  final String message;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => EmptyState(
    key: HistoryKeys.emptyFiltered,
    style: EmptyStateStyle.filters,
    message: message,
    actionLabel: context.l10n.endgamesFiltersClearAll,
    actionKey: HistoryKeys.emptyClear,
    onAction: onClear,
  );
}

/// O placar de três colunas iguais: o número em cima e o rótulo embaixo.
class HistoryScore extends StatelessWidget {
  const HistoryScore({required this.items, super.key})
    : assert(items.length == 3);

  /// Número e rótulo de cada coluna.
  final List<(int, String)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      // Topo 12, lados 16 (artboard); sem margem embaixo: o grupo traz a sua.
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, (number, label)) in items.indexed)
                Expanded(
                  child: Column(
                    key: HistoryKeys.score(index),
                    children: [
                      Text(
                        '$number',
                        maxLines: 1,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
