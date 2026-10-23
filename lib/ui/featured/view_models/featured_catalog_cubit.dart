import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/featured/featured_progress_repository.dart';
import '../../../data/repositories/featured/featured_repository.dart';
import '../../../domain/models/featured.dart';
import '../../../domain/use_cases/featured_rules.dart';
import '../../../domain/use_cases/now.dart';

/// A lista de finais em destaque, com os filtros de país e de origem.
class FeaturedCatalogState {
  const FeaturedCatalogState({
    this.ready = false,
    this.catalog = FeaturedCatalog.empty,
    this.items = const [],
    this.ongoing = const [],
    this.countries = const [],
    this.filter = FeaturedFilter.none,
  });

  final bool ready;
  final FeaturedCatalog catalog;

  /// Os finais que passam pelos filtros, na ordem da lista.
  final List<FeaturedItem> items;

  /// Os torneios em andamento, no topo.
  final List<FeaturedTournament> ongoing;

  /// Os países que têm final (para o filtro).
  final List<String> countries;
  final FeaturedFilter filter;

  /// Não há nenhum final no app (sem filtro nenhum).
  bool get isEmpty => ready && catalog.finals.isEmpty;

  /// Os filtros esconderam tudo.
  bool get filteredOut => ready && !isEmpty && items.isEmpty && ongoing.isEmpty;
}

class FeaturedCatalogCubit extends Cubit<FeaturedCatalogState> {
  /// [country] é o país do perfil: a lista abre filtrada por ele quando há
  /// final de lá (E1.21); o filtro de país continua à mão para ver outros.
  FeaturedCatalogCubit({
    required this._featured,
    required this._progress,
    required this._now,
    this._country,
  }) : super(const FeaturedCatalogState());

  final FeaturedRepository _featured;
  final FeaturedProgressRepository _progress;
  final Now _now;
  final String? _country;

  List<FeaturedItem> _all = const [];

  Future<void> load() async {
    final catalog = await _featured.catalog();
    final played = await _progress.played();
    if (isClosed) return;
    final now = _now();
    _all = FeaturedRules.items(catalog, played, now: now);
    final country = _country;
    final first = !state.ready;
    final filter =
        first &&
            country != null &&
            FeaturedRules.countries(catalog).contains(country)
        ? state.filter.copyWith(country: country)
        : state.filter;
    emit(_build(catalog, filter));
  }

  void setCountry(String? country) => _filter(
    country == null
        ? state.filter.copyWith(clearCountry: true)
        : state.filter.copyWith(country: country),
  );

  void setOrigin(FeaturedOrigin? origin) => _filter(
    origin == null
        ? state.filter.copyWith(clearOrigin: true)
        : state.filter.copyWith(origin: origin),
  );

  void clearFilters() => _filter(FeaturedFilter.none);

  void _filter(FeaturedFilter filter) {
    if (!state.ready) return;
    emit(_build(state.catalog, filter));
  }

  FeaturedCatalogState _build(FeaturedCatalog catalog, FeaturedFilter filter) =>
      FeaturedCatalogState(
        ready: true,
        catalog: catalog,
        items: FeaturedRules.filtered(_all, filter),
        ongoing: FeaturedRules.ongoing(catalog, filter, now: _now()),
        countries: FeaturedRules.countries(catalog),
        filter: filter,
      );
}
