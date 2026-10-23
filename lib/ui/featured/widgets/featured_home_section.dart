import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/use_cases/featured_rules.dart';
import '../../../routing/routes.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import 'featured_card.dart';

/// A seção "Finais em destaque" da tela inicial: o título, "Ver todos" e o
/// final em destaque. [daily], quando há, vem entre o título e o destaque.
class FeaturedHomeSection extends StatelessWidget {
  const FeaturedHomeSection({required this.item, this.daily, super.key});

  final FeaturedItem item;
  final Widget? daily;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: FeaturedKeys.homeSection,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.xs,
            AppSpacing.md,
            0,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(l10n.featuredTitle, style: context.sectionTitle),
                ),
              ),
              TextButton(
                key: FeaturedKeys.homeSeeAll,
                onPressed: () => context.go(Routes.featured),
                child: Text(l10n.featuredSeeAll),
              ),
            ],
          ),
        ),
        if (daily != null) ...[daily!, const SizedBox(height: AppSpacing.md)],
        FeaturedCard(
          key: FeaturedKeys.homeCard,
          item: item,
          onTap: () => context.go(Routes.featuredEndgame(item.id)),
        ),
      ],
    );
  }
}
