import 'package:flutter/material.dart';

import '../../../domain/models/featured.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_chip.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/external_page_sheet.dart';

/// Os links de um torneio: em andamento, "Resultados" e "Transmissão ao
/// vivo"; terminado, só "Sobre o torneio" (canvas CompChip, `info`).
class FeaturedLinkChips extends StatelessWidget {
  const FeaturedLinkChips({required this.tournament, this.ongoing, super.key});

  final FeaturedTournament tournament;

  /// Nulo mostra todos os links (o livrinho do final).
  final bool? ongoing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final kind in FeaturedLinkKind.values)
          if (ongoing == null || (kind == FeaturedLinkKind.info) != ongoing)
            if (tournament.link(kind) case final url?)
              ActionChip(
                key: switch (kind) {
                  FeaturedLinkKind.results =>
                    FeaturedKeys.tournamentLinkResults,
                  FeaturedLinkKind.broadcast => FeaturedKeys.tournamentLinkLive,
                  FeaturedLinkKind.info => FeaturedKeys.tournamentLinkAbout,
                },
                materialTapTargetSize: AppChip.tapTarget,
                visualDensity: AppChip.density,
                backgroundColor: colors.surfaceContainer,
                side: BorderSide.none,
                avatar: Icon(
                  Icons.open_in_new,
                  size: AppIconSize.small,
                  color: colors.onSurface,
                ),
                label: Text(switch (kind) {
                  FeaturedLinkKind.results => l10n.featuredLinkResults,
                  FeaturedLinkKind.broadcast => l10n.featuredLinkBroadcast,
                  FeaturedLinkKind.info => l10n.featuredLinkInfo,
                }),
                onPressed: () => showExternalPage(context, url),
              ),
      ],
    );
  }
}
