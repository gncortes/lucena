import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/alerts/region_prompt_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../routing/routes.dart';
import '../../core/keys/featured_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../region/widgets/region_sheet.dart';
import '../view_models/featured_catalog_cubit.dart';
import 'featured_card.dart';
import 'featured_labels.dart';
import 'featured_tournament_card.dart';

/// Todos os finais em destaque, com filtro de país e de origem. O torneio em
/// andamento fica no topo.
class FeaturedListScreen extends StatefulWidget {
  const FeaturedListScreen({super.key});

  @override
  State<FeaturedListScreen> createState() => _FeaturedListScreenState();
}

class _FeaturedListScreenState extends State<FeaturedListScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_askRegion());
  }

  /// Na primeira abertura, a folha de estado e cidade (E1.21), uma vez só.
  Future<void> _askRegion() async {
    if (!await context.read<RegionPromptRepository>().pending()) return;
    if (!mounted) return;
    await showRegionSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: FeaturedKeys.listScreen,
      appBar: LucenaAppBar(title: Text(l10n.featuredTitle)),
      body: BlocBuilder<FeaturedCatalogCubit, FeaturedCatalogState>(
        builder: (context, state) {
          if (!state.ready) return const SizedBox.shrink();
          if (state.isEmpty) {
            return Center(
              child: EmptyState(
                messageKey: FeaturedKeys.listEmpty,
                icon: Icons.flag_outlined,
                message: l10n.featuredEmpty,
              ),
            );
          }
          return ListView(
            padding: scrollPadding(context, left: 16, right: 16),
            children: [
              _Filters(state: state),
              if (state.filteredOut)
                EmptyState(
                  style: EmptyStateStyle.filters,
                  messageKey: FeaturedKeys.listFilteredOut,
                  message: l10n.featuredEmptyFilters,
                  actionLabel: l10n.featuredClearFilters,
                  actionKey: FeaturedKeys.clearFilters,
                  onAction: context.read<FeaturedCatalogCubit>().clearFilters,
                ),
              if (state.ongoing.isNotEmpty) ...[
                SectionTitle(
                  l10n.featuredOngoing,
                  textKey: FeaturedKeys.ongoingTitle,
                ),
                for (final tournament in state.ongoing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FeaturedTournamentCard(
                      tournament: tournament,
                      onTap: () => _open(
                        context,
                        Routes.featuredTournament(tournament.id),
                      ),
                    ),
                  ),
              ],
              if (state.items.isNotEmpty) ...[
                SectionTitle(l10n.featuredRecent),
                for (final item in state.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FeaturedCard(
                      item: item,
                      onTap: () =>
                          _open(context, Routes.featuredEndgame(item.id)),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Abre a rota e, ao voltar, recarrega a lista: o final jogado vira "Jogado" e
/// vai para o fim.
Future<void> _open(BuildContext context, String route) async {
  final cubit = context.read<FeaturedCatalogCubit>();
  await context.push(route);
  if (!cubit.isClosed) await cubit.load();
}

/// O país e a origem.
class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final FeaturedCatalogState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<FeaturedCatalogCubit>();
    final filter = state.filter;
    final origins = [
      for (final origin in FeaturedOrigin.values)
        if (state.catalog.finals.any((each) => each.origin == origin)) origin,
    ];
    final countries = [...state.countries]
      ..sort(
        (a, b) => FeaturedLabels.country(l10n, a).toLowerCase().compareTo(
          FeaturedLabels.country(l10n, b).toLowerCase(),
        ),
      );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (countries.isNotEmpty) ...[
            // "Todos os países" usa um valor vazio: com `null` o menu fecha
            // como cancelado e não chama `onSelected`.
            PopupMenuButton<String>(
              key: FeaturedKeys.countryFilter,
              tooltip: l10n.featuredFilterCountry,
              onSelected: (code) =>
                  cubit.setCountry(code.isEmpty ? null : code),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  key: FeaturedKeys.countryAll,
                  value: '',
                  child: Text(l10n.featuredCountryAll),
                ),
                for (final code in countries)
                  PopupMenuItem<String>(
                    key: FeaturedKeys.countryOption(code),
                    value: code,
                    child: Text(FeaturedLabels.country(l10n, code)),
                  ),
              ],
              child: IgnorePointer(
                child: ChoiceChip(
                  materialTapTargetSize: AppChip.tapTarget,
                  visualDensity: AppChip.density,
                  selected: filter.country != null,
                  onSelected: (_) {},
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter.country == null
                            ? l10n.featuredCountryAll
                            : FeaturedLabels.country(l10n, filter.country!),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: AppIconSize.button,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          ChoiceChip(
            key: FeaturedKeys.originAll,
            materialTapTargetSize: AppChip.tapTarget,
            visualDensity: AppChip.density,
            label: Text(l10n.featuredOriginAll),
            selected: filter.origin == null,
            onSelected: (_) => cubit.setOrigin(null),
          ),
          for (final origin in origins) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              key: FeaturedKeys.originFilter(origin.name),
              materialTapTargetSize: AppChip.tapTarget,
              visualDensity: AppChip.density,
              label: Text(l10n.featuredOriginFilter(origin.name)),
              selected: filter.origin == origin,
              onSelected: (_) => cubit.setOrigin(origin),
            ),
          ],
        ],
      ),
    );
  }
}
