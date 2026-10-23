import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/featured.dart';
import '../../../routing/routes.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/featured_tournament_cubit.dart';
import 'featured_card.dart';
import 'featured_labels.dart';
import 'featured_link_chip.dart';

/// Um torneio: o resumo, os links de resultados e de transmissão, os finais
/// dele e o aviso de final novo (quando há canal para ele).
class FeaturedTournamentScreen extends StatelessWidget {
  const FeaturedTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<FeaturedTournamentCubit, FeaturedTournamentState>(
      builder: (context, state) {
        final tournament = state.tournament;
        return Scaffold(
          key: FeaturedKeys.tournamentScreen,
          appBar: LucenaAppBar(title: Text(l10n.featuredOriginTournament)),
          body: !state.ready
              ? const SizedBox.shrink()
              : tournament == null
              ? Center(
                  child: EmptyState(
                    messageKey: FeaturedKeys.tournamentMissing,
                    icon: Icons.flag_outlined,
                    message: l10n.featuredTournamentMissing,
                  ),
                )
              : _Body(state: state, tournament: tournament),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.tournament});

  final FeaturedTournamentState state;
  final FeaturedTournament tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final summary = tournament.summary.of(language);
    final place = tournament.placeIn(language);
    final colors = theme.colorScheme;
    final details = [?place, '${tournament.year}'].join(' · ');
    return ListView(
      padding: scrollPadding(context, left: 16, right: 16),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
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
                    if (state.ongoing)
                      InfoChip(
                        key: FeaturedKeys.tournamentOngoing,
                        compact: true,
                        label: l10n.featuredLive,
                      ),
                  ],
                ),
                Text(
                  tournament.nameIn(language),
                  key: FeaturedKeys.tournamentName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  details,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    key: FeaturedKeys.tournamentSummary,
                    style: theme.textTheme.bodyMedium,
                  ),
                FeaturedLinkChips(tournament: tournament),
              ],
            ),
          ),
        ),
        if (state.alertAvailable)
          SwitchListTile(
            key: FeaturedKeys.tournamentAlert,
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.featuredAlertTournament),
            value: state.alertOn,
            onChanged: (value) =>
                context.read<FeaturedTournamentCubit>().setAlert(value: value),
          ),
        if (state.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Text(
              l10n.featuredTournamentNoFinals,
              key: FeaturedKeys.tournamentNoFinals,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          SectionTitle(l10n.featuredTournamentFinals),
          for (final item in state.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: FeaturedCard(
                item: item,
                onTap: () => _open(context, Routes.featuredEndgame(item.id)),
              ),
            ),
        ],
      ],
    );
  }

  /// Abre o final e, ao voltar, recarrega o torneio (o "Jogado" aparece).
  static Future<void> _open(BuildContext context, String route) async {
    final cubit = context.read<FeaturedTournamentCubit>();
    await context.push(route);
    if (!cubit.isClosed) await cubit.load();
  }
}
