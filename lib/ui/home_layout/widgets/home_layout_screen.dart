import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/use_cases/home_suggestion.dart';
import '../../core/keys/home_layout_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../home/widgets/home_path_ui.dart';
import '../view_models/home_layout_cubit.dart';

/// "Tela inicial": os cinco caminhos, com a caixa de marcar (em destaque ou
/// em "Outros modos") e a alça de arrastar (a ordem). Com leitor de tela, as
/// ações de mover para cima e para baixo do `ReorderableListView` fazem o
/// mesmo sem arrastar.
class HomeLayoutScreen extends StatelessWidget {
  const HomeLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<HomeLayoutCubit>();
    final state = context.watch<HomeLayoutCubit>().state;
    final layout = state.layout;
    return Scaffold(
      key: HomeLayoutKeys.screen,
      appBar: AppBar(title: Text(l10n.homeLayoutTitle)),
      bottomNavigationBar: layout == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: OutlinedButton.icon(
                  key: HomeLayoutKeys.restore,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.restart_alt),
                  label: Text(l10n.homeLayoutRestore),
                  onPressed: state.isSuggestion ? null : cubit.restore,
                ),
              ),
            ),
      body: layout == null
          ? const Center(child: CircularProgressIndicator())
          : ReorderableListView(
              key: HomeLayoutKeys.list,
              padding: scrollPadding(context),
              buildDefaultDragHandles: false,
              header: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l10n.homeLayoutBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              onReorderItem: cubit.reorder,
              children: [
                for (final (index, path) in layout.order.indexed)
                  Material(
                    key: HomeLayoutKeys.item(path),
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      key: HomeLayoutKeys.check(path),
                      controlAffinity: ListTileControlAffinity.leading,
                      value: layout.visible.contains(path),
                      // O último marcado não sai: a tela inicial nunca fica
                      // vazia.
                      enabled: HomeSuggestion.canHide(layout, path),
                      onChanged: (_) => cubit.toggle(path),
                      secondary: ReorderableDragStartListener(
                        key: HomeLayoutKeys.handle(path),
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                      title: Row(
                        children: [
                          Icon(path.icon, size: 20),
                          const SizedBox(width: 8),
                          Flexible(child: Text(path.title(l10n))),
                        ],
                      ),
                      subtitle: Text(path.body(l10n, state.level)),
                    ),
                  ),
              ],
            ),
    );
  }
}
