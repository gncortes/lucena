import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/daily_final.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/position_board.dart';
import '../../featured/widgets/featured_card.dart';
import '../../streak/widgets/streak_pill.dart';
import 'daily_squares.dart';

/// O final do dia na home (canvas `PropV1RetencaoHome`): a faixa com a data
/// e a sequência (a pílula abre a Sequência; sem sequência, some) e o cartão
/// do final com o selo "HOJE", que abre a partida.
class DailyHomeCard extends StatelessWidget {
  const DailyHomeCard({required this.daily, required this.streak, super.key});

  final DailyFinal daily;

  /// Os dias seguidos agora.
  final int streak;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final position = daily.position;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          key: DailyKeys.homeStrip,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            0,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.today,
                size: AppIconSize.button,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.dailyTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  dailyDate(context, daily.date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (streak > 0)
                InkWell(
                  key: DailyKeys.streakPill,
                  borderRadius: BorderRadius.circular(AppShape.full),
                  onTap: () => unawaited(context.push(Routes.streak)),
                  child: StreakPill(days: streak),
                ),
            ],
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => unawaited(context.push(Routes.daily)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.md,
                children: [
                  ExcludeSemantics(
                    child: PositionBoard(
                      fen: position.fen,
                      size: FeaturedCard.thumbnail,
                      radius: AppShape.small,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.xs,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                categoryName(l10n, position.category),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: AppWeight.strong,
                                ),
                              ),
                            ),
                            Text(
                              l10n.dailyBadge,
                              key: DailyKeys.badge,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: AppWeight.strong,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          endgameName(l10n, position.subcategory),
                          style: context.cardTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          goalLabel(l10n, position.goal),
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
        ),
      ],
    );
  }
}
