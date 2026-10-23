import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui_board.dart';

import '../../../domain/use_cases/featured_rules.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import 'featured_labels.dart';

/// Um final em destaque numa lista: miniatura, origem, título, quem jogou e o
/// tema. Na tela inicial e na lista. Adaptador: o desenho é do `lucena_ui`.
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({required this.item, required this.onTap, super.key});

  static const thumbnail = FeaturedCardView.thumbnail;

  final FeaturedItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final endgame = item.endgame;
    final topic = endgame.theme;
    return FeaturedCardView(
      cardKey: FeaturedKeys.card(item.id),
      originKey: FeaturedKeys.cardOrigin,
      fen: endgame.fen,
      originIcon: FeaturedLabels.originIcon(endgame.origin),
      originLabel: FeaturedLabels.origin(l10n, endgame.origin),
      mark: item.played
          ? FeaturedMark.played
          : item.isNew
          ? FeaturedMark.isNew
          : FeaturedMark.none,
      markKey: item.played ? FeaturedKeys.cardPlayed : FeaturedKeys.cardNew,
      markLabel: item.played
          ? l10n.featuredPlayed
          : l10n.featuredNew.toUpperCase(),
      title: endgame.title.of(language),
      subtitle:
          '${FeaturedLabels.shortPlayers(l10n, endgame)} · '
          '${FeaturedLabels.subtitle(l10n, language, endgame, item.tournament, inline: true)}',
      topic: topic == null ? null : FeaturedLabels.theme(l10n, topic),
      onTap: onTap,
    );
  }
}
