import 'package:flutter/material.dart';

import '../../../domain/models/featured.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/motion/tabuleiro_hero.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/position_board.dart';
import 'featured_labels.dart';

/// Um final em destaque numa lista (canvas `PropV1DesLista`): miniatura, os
/// selos (Torneio, NOVO, Histórica, Jogado), o título, quem jogou e o evento,
/// e o tema. [historic] põe o selo "Histórica" (a seção "Finais históricos").
/// [compact], na tela inicial: miniatura pequena, quem jogou e o evento, com
/// a seta.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    required this.item,
    required this.onTap,
    this.compact = false,
    this.historic = false,
    super.key,
  });

  static const thumbnail = 92.0;

  /// A miniatura da tela inicial (canvas `PropV2UxHome*`).
  static const compactThumbnail = 46.0;

  final FeaturedItem item;
  final VoidCallback onTap;
  final bool compact;
  final bool historic;

  @override
  Widget build(BuildContext context) {
    if (compact) return _compact(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final endgame = item.endgame;
    final title = endgame.title.of(language);
    final players = FeaturedLabels.shortPlayers(l10n, endgame);
    final event = FeaturedLabels.eventYear(
      l10n,
      language,
      endgame,
      item.tournament,
    );
    final themeLabel = endgame.theme;
    final badges = [
      if (endgame.origin == FeaturedOrigin.tournament)
        _Badge(
          key: FeaturedKeys.cardTournament,
          icon: FeaturedLabels.originIcon(FeaturedOrigin.tournament),
          label: l10n.featuredOriginTournament,
          color: colors.onSurfaceVariant,
        ),
      if (item.isNew)
        _Badge(
          key: FeaturedKeys.cardNew,
          label: l10n.featuredNew,
          color: colors.primary,
        ),
      if (historic)
        _Badge(
          key: FeaturedKeys.cardHistoric,
          icon: FeaturedLabels.originIcon(FeaturedOrigin.historical),
          label: l10n.featuredOriginHistorical,
          color: colors.onSurfaceVariant,
        ),
      if (item.played)
        _Badge(
          key: FeaturedKeys.cardPlayed,
          icon: Icons.check_circle,
          label: l10n.featuredPlayed,
          color: AppColors.successColor,
        ),
    ];
    return KeyedSubtree(
      key: FeaturedKeys.card(item.id),
      child: LucenaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            ExcludeSemantics(
              child: TabuleiroHero(
                id: endgame.fen,
                child: PositionBoard(
                  fen: endgame.fen,
                  size: thumbnail,
                  radius: AppShape.small,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  if (badges.isNotEmpty)
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: badges,
                    ),
                  Text(
                    title.isEmpty ? players : title,
                    style: context.cardTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title.isEmpty ? event : '$players · $event',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    themeLabel == null
                        ? goalLabel(l10n, endgame.goal)
                        : FeaturedLabels.theme(l10n, themeLabel),
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
    );
  }
}

extension on FeaturedCard {
  Widget _compact(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final endgame = item.endgame;
    return Material(
      key: FeaturedKeys.card(item.id),
      color: colors.surfaceContainerLow,
      // #FAFBF9 com contorno 1px #E1E5DF (H-INI-05).
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.large),
        side: const BorderSide(color: AppColors.cardOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              ExcludeSemantics(
                child: TabuleiroHero(
                  id: endgame.fen,
                  child: PositionBoard(
                    fen: endgame.fen,
                    size: FeaturedCard.compactThumbnail,
                    radius: AppShape.small,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      FeaturedLabels.shortPlayers(l10n, endgame),
                      style: context.cardTitle?.copyWith(
                        fontWeight: AppWeight.heavy,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      FeaturedLabels.eventYear(
                        l10n,
                        language,
                        endgame,
                        item.tournament,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
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
