import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/catalog_cubit.dart';
import 'catalog_ui.dart';

/// As subcategorias de uma categoria, cada uma com o material em figurino.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({required this.category, super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final state = context.watch<CatalogCubit>().state;
    final subcategories = [
      for (final c in state.categories ?? const [])
        if (c.key == category)
          for (final sub in c.subcategories)
            if (sub.count(state.filter) > 0) sub,
    ];
    return Scaffold(
      key: CatalogKeys.categoryScreen,
      appBar: AppBar(title: Text(categoryName(l10n, category))),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: state.categories == null
                ? const Center(child: CircularProgressIndicator())
                : subcategories.isEmpty
                ? const CatalogEmpty()
                : ListView.builder(
                    itemCount: subcategories.length,
                    itemBuilder: (context, index) {
                      final sub = subcategories[index];
                      return ListTile(
                        key: CatalogKeys.subcategory(sub.key),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        title: SubcategoryMaterialText(
                          sub.key,
                          style: theme.textTheme.titleLarge,
                        ),
                        subtitle: Text(
                          l10n.catalogPositionCount(sub.count(state.filter)),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(
                          Routes.catalogSubcategory(category, sub.key),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
