import 'package:flutter/material.dart';

import '../../../domain/models/featured.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/lucena_card.dart';
import 'featured_labels.dart';

/// O cartão de um torneio no carrossel da lista (canvas `PropV1DesLista`,
/// 300 por 132): selos "Torneio" e "Em andamento", o nome, o local e quantos
/// finais há para praticar.
class FeaturedTournamentCard extends StatelessWidget {
  const FeaturedTournamentCard({
    required this.tournament,
    required this.finals,
    required this.onTap,
    super.key,
  });

  static const width = 300.0;
  static const height = 132.0;

  final FeaturedTournament tournament;

  /// Quantos finais do torneio estão no app.
  final int finals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final place = tournament.placeIn(language);
    return SizedBox(
      width: width,
      height: height,
      child: KeyedSubtree(
        key: FeaturedKeys.tournamentCard(tournament.id),
        child: LucenaCard(
          onTap: onTap,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    InfoChip(
                      compact: true,
                      background: colors.primaryContainer,
                      foreground: colors.primary,
                      icon: FeaturedLabels.originIcon(
                        FeaturedOrigin.tournament,
                      ),
                      label: l10n.featuredOriginTournament,
                    ),
                    InfoChip(
                      compact: true,
                      outlined: true,
                      label: l10n.featuredLive,
                    ),
                  ],
                ),
              ),
              Text(
                tournament.nameIn(language),
                style: context.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (place != null)
                Text(
                  place,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const Spacer(),
              Row(
                spacing: AppSpacing.xs,
                children: [
                  Expanded(
                    child: Text(
                      l10n.desafiosFeaturedTournamentFinals(finals),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: AppWeight.strong,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: AppIconSize.button,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
