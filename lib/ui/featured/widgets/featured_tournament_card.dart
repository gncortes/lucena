import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../domain/models/featured.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import 'featured_labels.dart';

/// O cartão de um torneio (em andamento, na lista): chip, nome, resumo e a
/// seta para a tela dele. Adaptador: o desenho é do `lucena_ui`.
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
    final language = Localizations.localeOf(context).languageCode;
    return FeaturedTournamentCardView(
      cardKey: FeaturedKeys.tournamentCard(tournament.id),
      chipIcon: FeaturedLabels.originIcon(FeaturedOrigin.tournament),
      chipLabel: context.l10n.featuredOriginTournament,
      name: tournament.nameIn(language),
      place: tournament.placeIn(language),
      summary: tournament.summary.of(language),
      onTap: onTap,
    );
  }
}
