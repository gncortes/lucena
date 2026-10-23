import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';

import '../../../domain/models/speedrun.dart';
import '../../../domain/use_cases/endgame_difficulty.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../routing/routes.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/figurine.dart';
import '../view_models/catalog_cubit.dart';
import 'catalog_ui.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/skeleton.dart';

/// As categorias do catálogo, com o filtro por objetivo.
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CatalogCubit>().state;
    final categories = state.categories;
    return Scaffold(
      key: CatalogKeys.screen,
      appBar: LucenaAppBar(title: Text(context.l10n.catalogTitle)),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: categories == null
                ? const SkeletonList()
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

  /// Quantos finais o cartão mostra pelo nome; os outros viram "+N".
  static const _shownEndgames = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final total = category.count(GoalFilter.all);
    final subcategories = [
      for (final sub in category.subcategories)
        if (sub.count(filter) > 0) sub,
    ];
    return Card(
      key: CatalogKeys.category(category.key),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Routes.catalogCategory(category.key)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                      borderRadius: BorderRadius.circular(AppShape.large),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName(l10n, category.key),
                          key: CatalogKeys.categoryName(category.key),
                          style: context.cardTitle,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                l10n.catalogPositionCount(
                                  category.count(filter),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            // Por onde começar: o selo da dificuldade.
                            if (EndgameDifficulty.ofCategory(category)
                                case final difficulty?) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _DifficultyBadge(
                                key: CatalogKeys.difficulty(category.key),
                                difficulty: difficulty,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Os primeiros finais da categoria, pelo nome, e quantos mais.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final sub in subcategories.take(_shownEndgames))
                    InfoChip(label: endgameName(l10n, sub.key)),
                  if (subcategories.length > _shownEndgames)
                    InfoChip(
                      key: CatalogKeys.moreEndgames(category.key),
                      label: l10n.catalogMoreEndgames(
                        subcategories.length - _shownEndgames,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedProgress(
                value: total == 0 ? 0 : done / total,
                role: ProgressRole.success,
                backgroundColor: colors.surfaceContainerHighest,
              ),
              const SizedBox(height: AppSpacing.xs),
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

/// O selo de dificuldade de um grupo de finais.
class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty, super.key});

  final SpeedrunCategory difficulty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // Os três níveis no mesmo azul claro do design system (Gabriel, 14/10/2026).
    final label = switch (difficulty) {
      SpeedrunCategory.beginner => l10n.profileLevelBeginner,
      SpeedrunCategory.intermediate => l10n.profileLevelIntermediate,
      SpeedrunCategory.advanced => l10n.profileLevelAdvanced,
    };
    return InfoChip(
      label: label,
      background: colors.secondaryContainer,
      foreground: colors.onSecondaryContainer,
    );
  }
}
