import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/featured.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/external_page_sheet.dart';

/// Os links de um torneio (resultados, transmissão, sobre): chips cinza com o
/// ícone de abrir fora (canvas CompChip, `info`).
class FeaturedLinkChips extends StatelessWidget {
  const FeaturedLinkChips({required this.tournament, super.key});

  final FeaturedTournament tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final kind in FeaturedLinkKind.values)
          if (tournament.link(kind) case final url?)
            ActionChip(
              key: FeaturedKeys.tournamentLink(kind.name),
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
