import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../routing/routes.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';
import '../../core/widgets/goal_style.dart';
import '../view_models/catalog_cubit.dart';
import 'catalog_ui.dart';
import '../../core/widgets/scroll_padding.dart';

/// As categorias do catálogo, com o filtro por objetivo.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogCubit>().state;
    final categories = state.categories;
    return Scaffold(
      key: CatalogKeys.screen,
      appBar: AppBar(title: Text(context.l10n.catalogTitle)),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: categories == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: scrollPadding(context, left: 16, right: 16),
                    children: [
                      for (final category in categories)
                        if (category.count(state.filter) > 0)
                          _CategoryCard(
                            category: category,
                            filter: state.filter,
                            done: state.fulfilled
                                .where(
                                  (id) => id.startsWith('${category.key}.'),
                                )
                                .length,
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Uma categoria: as peças dela em destaque, o nome, os finais em selos com
/// o nome por extenso e quantas posições o jogador já resolveu.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.filter,
    required this.done,
  });

  final CatalogCategory category;
  final GoalFilter filter;

  /// Quantas posições da categoria já tiveram o objetivo cumprido.
  final int done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final total = category.count(GoalFilter.all);
    return Card(
      key: CatalogKeys.category(category.key),
      margin: const EdgeInsets.only(bottom: 12),
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Routes.catalogCategory(category.key)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: ExcludeSemantics(
                      // Duas peças (♖♙) cabem lado a lado, menores.
                      child: FittedBox(
                        child: Text(
                          categoryFigurines(category.key),
                          textDirection: TextDirection.ltr,
                          softWrap: false,
                          style: TextStyle(
                            fontFamily: Figurine.fontFamily,
                            fontSize: 34,
                            height: 1,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName(l10n, category.key),
                          key: CatalogKeys.categoryName(category.key),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.catalogPositionCount(category.count(filter)),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              // Os finais da categoria, pelo nome.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final sub in category.subcategories)
                    if (sub.count(filter) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          endgameName(l10n, sub.key),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 6,
                  color: ChangeColors.of(context, up: true),
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.catalogDone(done, total),
                key: CatalogKeys.categoryDone(category.key),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
