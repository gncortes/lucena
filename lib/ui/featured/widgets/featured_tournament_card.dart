import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/featured.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import 'featured_labels.dart';

/// O cartão de um torneio (em andamento, na lista): chip, nome, resumo e a
/// seta para a tela dele.
class FeaturedTournamentCard extends StatelessWidget {
  const FeaturedTournamentCard({
    required this.tournament,
    required this.onTap,
    super.key,
  });

  final FeaturedTournament tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    final place = tournament.placeIn(language);
    final summary = tournament.summary.of(language);
    return Card(
      key: FeaturedKeys.tournamentCard(tournament.id),
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShape.large),
        side: BorderSide(color: colors.primaryContainer, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    Row(
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
                        if (place != null)
                          Flexible(
                            child: Text(
                              place,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(tournament.nameIn(language), style: context.cardTitle),
                    if (summary.isNotEmpty)
                      Text(
                        summary,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
