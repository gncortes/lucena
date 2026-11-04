import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/featured.dart';
import '../../../routing/routes.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/info_chip.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/featured_tournament_cubit.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lista_em_ordem.dart';
import 'featured_card.dart';
import 'featured_labels.dart';
import 'featured_link_chip.dart';

/// Um torneio (canvas `PropV1DesTorneio*`): o cabeçalho com os links, e a
/// seção "Finais para praticar". Sem aviso por torneio.
class FeaturedTournamentScreen extends StatelessWidget {
  const FeaturedTournamentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FeaturedTournamentCubit>().state;
    if (state.failure case final failure?) {
      return LoadErrorScreen(
        kind: LoadErrorKind.fromFailure(failure),
        onAction: context.read<FeaturedTournamentCubit>().retryLoad,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      );
    }
    final l10n = context.l10n;
    if (!state.ready) {
      return KeyedSubtree(
        key: FeaturedKeys.tournamentLoading,
        child: LoadSkeletonScreen(
          title: l10n.featuredOriginTournament,
          blocks: const [
            SkeletonShape.card(200),
            SkeletonShape.card(64),
            SkeletonShape.line(140),
            SkeletonShape.card(120),
            SkeletonShape.card(120),
          ],
        ),
      );
    }
    final tournament = state.tournament;
    if (tournament == null) {
      return KeyedSubtree(
        key: FeaturedKeys.tournamentMissing,
        child: LoadErrorScreen(
          kind: LoadErrorKind.notFound,
          onAction: () => context.go(Routes.home),
        ),
      );
    }
    return Scaffold(
      key: FeaturedKeys.tournamentScreen,
      appBar: LucenaAppBar(title: Text(l10n.featuredOriginTournament)),
      body: _Body(state: state, tournament: tournament),
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
    final monthDay = DateFormat.MMMMd(language);
    final start = tournament.startsOn;
    final end = tournament.endsOn;
    final when = state.ongoing && start != null && end != null
        ? l10n.desafiosTournamentDates(
            // "17 a 25 de outubro" no mesmo mês; senão cada data com o mês.
            (start.month == end.month ? DateFormat.d(language) : monthDay)
                .format(start),
            monthDay.format(end),
          )
        : '${tournament.year}';
    final details = [?place, when].join(' · ');
    return EntradaDaTela(
      id: 'DesafiosTorneio.${tournament.id}',
      child: ListaEmOrdem(
        montar: (itens) => ListView(
          padding: scrollPadding(context, left: 16, right: 16),
          children: itens,
        ),
        itens: [
          LucenaCard(
            key: FeaturedKeys.tournamentHeader,
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
                FeaturedLinkChips(
                  tournament: tournament,
                  ongoing: state.ongoing,
                ),
              ],
            ),
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
            SectionTitle(
              l10n.desafiosFeaturedPractice,
              textKey: FeaturedKeys.tournamentPractice,
            ),
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
      ),
    );
  }

  /// Abre o final e, ao voltar, recarrega o torneio (o "Jogado" aparece).
  static Future<void> _open(BuildContext context, String route) async {
    final cubit = context.read<FeaturedTournamentCubit>();
    await context.push(route);
    if (!cubit.isClosed) await cubit.load();
  }
}
