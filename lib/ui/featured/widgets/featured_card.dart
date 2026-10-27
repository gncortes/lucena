import 'package:flutter/material.dart';

import '../../../domain/use_cases/featured_rules.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/position_board.dart';
import 'featured_labels.dart';

/// Um final em destaque numa lista: miniatura, quem jogou (o título), evento e
/// ano, e a meta (sem selo de novo nem de origem). Na tela inicial e na lista.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({required this.item, required this.onTap, super.key});

  static const thumbnail = 92.0;

  final FeaturedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final endgame = item.endgame;
    return Card(
      key: FeaturedKeys.card(item.id),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.md,
            children: [
              ExcludeSemantics(
                child: PositionBoard(
                  fen: endgame.fen,
                  size: thumbnail,
                  radius: AppShape.small,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    if (item.played)
                      _Badge(
                        key: FeaturedKeys.cardPlayed,
                        icon: Icons.check_circle,
                        label: l10n.featuredPlayed,
                        color: AppColors.successColor,
                      ),
                    Text(
                      FeaturedLabels.shortPlayers(l10n, endgame),
                      style: context.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      FeaturedLabels.eventYear(
                        l10n,
                        language,
                        endgame,
                        item.tournament,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      goalLabel(l10n, endgame.goal),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: color, fontWeight: AppWeight.strong);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.xs,
      children: [
        if (icon != null) Icon(icon, size: AppIconSize.small, color: color),
        Text(label, style: style),
      ],
    );
  }
}
