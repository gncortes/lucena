import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/use_cases/featured_rules.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/position_board.dart';
import 'featured_labels.dart';

/// Um final em destaque numa lista: miniatura, origem, título, quem jogou e o
/// tema. Na tela inicial e na lista.
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
    final topic = endgame.theme;
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
                    Row(
                      children: [
                        InfoChip(
                          key: FeaturedKeys.cardOrigin,
                          compact: true,
                          background: colors.primaryContainer,
                          foreground: colors.primary,
                          icon: FeaturedLabels.originIcon(endgame.origin),
                          label: FeaturedLabels.origin(l10n, endgame.origin),
                        ),
                        const Spacer(),
                        if (item.played)
                          _Badge(
                            key: FeaturedKeys.cardPlayed,
                            icon: Icons.check_circle,
                            label: l10n.featuredPlayed,
                            color: AppColors.successColor,
                          )
                        else if (item.isNew)
                          _Badge(
                            key: FeaturedKeys.cardNew,
                            label: l10n.featuredNew.toUpperCase(),
                            color: colors.primary,
                          ),
                      ],
                    ),
                    Text(
                      endgame.title.of(language),
                      style: context.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${FeaturedLabels.shortPlayers(l10n, endgame)} · '
                      '${FeaturedLabels.subtitle(l10n, language, endgame, item.tournament, inline: true)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (topic != null)
                      Text(
                        FeaturedLabels.theme(l10n, topic),
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
