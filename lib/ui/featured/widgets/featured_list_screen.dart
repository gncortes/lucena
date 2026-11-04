import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/analytics_event.dart';
import '../../../routing/routes.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/skeleton.dart';
import '../view_models/featured_catalog_cubit.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/motion/lista_em_ordem.dart';
import 'featured_card.dart';
import 'featured_tournament_card.dart';

/// Os finais em destaque (canvas `PropV1DesLista`): o sino de finais novos na
/// app bar, o carrossel de torneios em andamento, "Finais recentes" (últimos
/// 30 dias) e "Finais históricos". Sem filtros.
class FeaturedListScreen extends StatelessWidget {
  const FeaturedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocConsumer<FeaturedCatalogCubit, FeaturedCatalogState>(
      listenWhen: (before, now) => before.noticeCount != now.noticeCount,
      listener: _showNotice,
      builder: (context, state) {
        if (state.failure case final failure?) {
          return KeyedSubtree(
            key: FeaturedKeys.listError,
            child: LoadErrorScreen(
              kind: LoadErrorKind.fromFailure(failure),
              onAction: context.read<FeaturedCatalogCubit>().retryLoad,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(Routes.home),
            ),
          );
        }
        if (!state.ready) {
          return Scaffold(
            key: FeaturedKeys.listLoading,
            appBar: LucenaAppBar(
              title: Text(l10n.featuredTitle),
              actions: [_Bell(state: state, enabled: false)],
            ),
            body: const SafeArea(child: SkeletonList()),
          );
        }
        return Scaffold(
          key: FeaturedKeys.listScreen,
          appBar: LucenaAppBar(
            title: Text(l10n.featuredTitle),
            actions: [_Bell(state: state)],
          ),
          body: state.isEmpty
              ? Center(
                  child: EmptyState(
                    messageKey: FeaturedKeys.listEmpty,
                    icon: Icons.emoji_events_outlined,
                    message: l10n.featuredEmpty,
                  ),
                )
              : _Sections(state: state),
        );
      },
    );
  }

  void _showNotice(BuildContext context, FeaturedCatalogState state) {
    final l10n = context.l10n;
    final notice = state.notice;
    if (notice == null) return;
    final cubit = context.read<FeaturedCatalogCubit>();
    switch (notice) {
      case FeaturedBellNotice.turnedOn:
      case FeaturedBellNotice.turnedOff:
        final on = notice == FeaturedBellNotice.turnedOn;
        context.analytics.log(AnalyticsEvents.finalDestaqueAviso(ligado: on));
        showLucenaSnackBar(
          context,
          on ? l10n.desafiosFeaturedBellOn : l10n.desafiosFeaturedBellOff,
          icon: on
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_outlined,
          key: FeaturedKeys.bellNotice,
        );
      case FeaturedBellNotice.permissionDenied:
        showLucenaSnackBar(
          context,
          l10n.desafiosFeaturedBellDenied,
          icon: Icons.notifications_off_outlined,
          key: FeaturedKeys.bellNotice,
          action: SnackBarAction(
            key: FeaturedKeys.bellSettings,
            label: l10n.desafiosFeaturedBellSettings,
            onPressed: cubit.openSystemSettings,
          ),
        );
    }
  }
}

/// O sino geral de finais novos.
class _Bell extends StatelessWidget {
  const _Bell({required this.state, this.enabled = true});

  final FeaturedCatalogState state;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: FeaturedKeys.bell,
      tooltip: context.l10n.desafiosFeaturedBellTooltip,
      onPressed: enabled
          ? context.read<FeaturedCatalogCubit>().toggleBell
          : null,
      icon: Icon(
        state.bellOn
            ? Icons.notifications_active_rounded
            : Icons.notifications_outlined,
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections({required this.state});

  final FeaturedCatalogState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<FeaturedCatalogCubit>();
    return EntradaDaTela(
      id: 'DesafiosLista',
      child: ListaEmOrdem(
        montar: (itens) => ListView(
          padding: scrollPadding(context, left: 16, right: 16),
          children: itens,
        ),
        itens: [
          if (state.ongoing.isNotEmpty) ...[
            SectionTitle(
              l10n.featuredOngoing,
              textKey: FeaturedKeys.ongoingTitle,
            ),
            SizedBox(
              key: FeaturedKeys.tournamentCarousel,
              height: FeaturedTournamentCard.height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.ongoing.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final tournament = state.ongoing[index];
                  return FeaturedTournamentCard(
                    tournament: tournament,
                    finals: state.finalsOf(tournament.id),
                    onTap: () => _open(
                      context,
                      cubit,
                      Routes.featuredTournament(tournament.id),
                    ),
                  );
                },
              ),
            ),
          ],
          if (state.recent.isNotEmpty) ...[
            SectionTitle(
              l10n.featuredRecent,
              textKey: FeaturedKeys.recentTitle,
            ),
            for (final item in state.recent)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FeaturedCard(
                  item: item,
                  onTap: () =>
                      _open(context, cubit, Routes.featuredEndgame(item.id)),
                ),
              ),
          ],
          if (state.historic.isNotEmpty) ...[
            SectionTitle(
              l10n.desafiosFeaturedHistoric,
              textKey: FeaturedKeys.historicTitle,
            ),
            for (final item in state.historic)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FeaturedCard(
                  item: item,
                  historic: true,
                  onTap: () =>
                      _open(context, cubit, Routes.featuredEndgame(item.id)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Abre a rota e, ao voltar, recarrega a lista: o final jogado vira "Jogado".
Future<void> _open(
  BuildContext context,
  FeaturedCatalogCubit cubit,
  String route,
) async {
  await context.push(route);
  if (!cubit.isClosed) await cubit.load();
}
