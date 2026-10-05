import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../routing/routes.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';
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
                          ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.filter});

  final CatalogCategory category;
  final GoalFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    return Card(
      key: CatalogKeys.category(category.key),
      margin: const EdgeInsets.only(bottom: 10),
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Routes.catalogCategory(category.key)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: ExcludeSemantics(
                  // Duas peças (♖♙) cabem lado a lado, menores.
                  child: FittedBox(
                    child: Text(
                      categoryFigurines(category.key),
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontFamily: Figurine.fontFamily,
                        fontSize: 28,
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
                        fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
