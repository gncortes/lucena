import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/featured.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/external_page_sheet.dart';
import 'featured_labels.dart';
import 'featured_link_chip.dart';

/// O livrinho do final ("Sobre a partida"): o torneio com os links, os
/// jogadores e o que aconteceu na partida, fechado para não virar dica.
Future<void> showFeaturedBook(
  BuildContext context, {
  required FeaturedEndgame endgame,
  FeaturedTournament? tournament,
}) {
  return showLucenaSheet<void>(
    context,
    sheetKey: FeaturedKeys.bookSheet,
    // Folha cinza: os cartões brancos aparecem sobre ela (canvas).
    color: Theme.of(context).colorScheme.surface,
    builder: (context) => SafeArea(
      top: false,
      child: FeaturedBook(endgame: endgame, tournament: tournament),
    ),
  );
}

class FeaturedBook extends StatelessWidget {
  const FeaturedBook({required this.endgame, this.tournament, super.key});

  final FeaturedEndgame endgame;
  final FeaturedTournament? tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final tournament = this.tournament;
    final happened = endgame.whatHappened.of(language);
    final gameUrl = endgame.gameUrl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.featuredBookTitle),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                if (tournament != null)
                  _TournamentCard(endgame: endgame, tournament: tournament),
                _PlayersCard(endgame: endgame),
                if (happened.isNotEmpty) _Happened(text: happened),
                if (gameUrl != null)
                  OutlinedButton.icon(
                    key: FeaturedKeys.bookFullGame,
                    icon: const Icon(
                      Icons.open_in_new,
                      size: AppIconSize.button,
                    ),
                    label: Text(l10n.featuredFullGame),
                    onPressed: () => showExternalPage(context, gameUrl),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.endgame, required this.tournament});

  final FeaturedEndgame endgame;
  final FeaturedTournament tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final place = tournament.placeIn(language);
    final round = endgame.round;
    final details = [
      ?place,
      '${tournament.year}',
      if (round != null) l10n.featuredRound(round),
    ].join(' · ');
    return _Panel(
      key: FeaturedKeys.bookTournament,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          InfoChip(
            compact: true,
            background: theme.colorScheme.primaryContainer,
            foreground: theme.colorScheme.primary,
            icon: FeaturedLabels.originIcon(FeaturedOrigin.tournament),
            label: l10n.featuredOriginTournament,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(tournament.nameIn(language), style: context.cardTitle),
          Text(
            details,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (tournament.links.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            FeaturedLinkChips(tournament: tournament),
          ],
        ],
      ),
    );
  }
}

class _PlayersCard extends StatelessWidget {
  const _PlayersCard({required this.endgame});

  final FeaturedEndgame endgame;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      key: FeaturedKeys.endgamePlayers,
      child: Column(
        spacing: AppSpacing.sm,
        children: [
          _PlayerRow(
            key: FeaturedKeys.bookWhite,
            player: endgame.white,
            white: true,
          ),
          _PlayerRow(
            key: FeaturedKeys.bookBlack,
            player: endgame.black,
            white: false,
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({required this.player, required this.white, super.key});

  final FeaturedPlayer player;
  final bool white;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final profile = player.profile;
    final country = player.country;
    final rating = player.rating;
    final details = [
      ?player.title,
      if (rating != null) '$rating',
      if (country != null) FeaturedLabels.country(l10n, country),
    ].join(' · ');
    final row = Row(
      spacing: AppSpacing.md,
      children: [
        // O lado da peça: bolinha branca ou preta.
        Container(
          width: AppIconSize.small,
          height: AppIconSize.small,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: white ? colors.surfaceContainerLow : colors.onSurface,
            border: Border.all(color: colors.outline),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (details.isNotEmpty)
                Text(
                  details,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (profile != null)
          Icon(
            Icons.open_in_new,
            size: AppIconSize.button,
            color: colors.primary,
          ),
      ],
    );
    if (profile == null) return row;
    return InkWell(onTap: () => showExternalPage(context, profile), child: row);
  }
}

/// "O que aconteceu na partida": fechado, para a resposta não virar dica.
class _Happened extends StatefulWidget {
  const _Happened({required this.text});

  final String text;

  @override
  State<_Happened> createState() => _HappenedState();
}

class _HappenedState extends State<_Happened> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: FeaturedKeys.bookHappened,
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        collapsedBackgroundColor: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.large),
        ),
        title: Text(l10n.featuredHappened, style: theme.textTheme.titleSmall),
        onExpansionChanged: (open) => setState(() => _open = open),
        subtitle: _open ? null : Text(l10n.featuredHappenedClosed),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(widget.text, key: FeaturedKeys.bookHappenedText)],
      ),
    );
  }
}
