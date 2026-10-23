import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/crowd_stat.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/featured_crowd_cubit.dart';

/// O cartão compacto acima dos botões do fim de um final em destaque
/// (canvas `PropV1RetencaoTorneioFim`): "41% acertaram · 1.284 pessoas
/// jogaram este final.", ou "Poucas pessoas jogaram este final" abaixo de
/// [CrowdStat.minTotal]. Sem o número, nada.
class FeaturedCrowdCard extends StatelessWidget {
  const FeaturedCrowdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeaturedCrowdCubit, CrowdStat?>(
      builder: (context, stat) {
        if (stat == null) return const SizedBox.shrink();
        final l10n = context.l10n;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final bold = theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        );
        final secondary = theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: DecoratedBox(
            key: FeaturedKeys.crowdCard,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppShape.large),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.groups, color: colors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: stat.enough
                          ? [
                              Text(
                                l10n.crowdPercent(stat.percent),
                                style: bold,
                              ),
                              Text(
                                l10n.crowdPlayersFinal(stat.total),
                                style: secondary,
                              ),
                            ]
                          : [
                              Text(
                                l10n.crowdFew,
                                key: FeaturedKeys.crowdFew,
                                style: bold,
                              ),
                              Text(l10n.crowdFewText, style: secondary),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
