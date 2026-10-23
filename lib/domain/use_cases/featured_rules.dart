import '../models/featured.dart';

/// Um final em destaque como a lista o mostra: com o torneio, se já foi
/// jogado e se é novo.
class FeaturedItem {
  const FeaturedItem({
    required this.endgame,
    required this.played,
    required this.isNew,
    this.tournament,
  });

  final FeaturedEndgame endgame;
  final FeaturedTournament? tournament;
  final bool played;
  final bool isNew;

  String get id => endgame.id;
}

/// Os filtros da lista: o país do torneio e a origem. Nulo é "todos".
class FeaturedFilter {
  const FeaturedFilter({this.country, this.origin});

  static const none = FeaturedFilter();

  final String? country;
  final FeaturedOrigin? origin;

  bool get isActive => country != null || origin != null;

  FeaturedFilter copyWith({
    String? country,
    FeaturedOrigin? origin,
    bool clearCountry = false,
    bool clearOrigin = false,
  }) => FeaturedFilter(
    country: clearCountry ? null : country ?? this.country,
    origin: clearOrigin ? null : origin ?? this.origin,
  );

  @override
  bool operator ==(Object other) =>
      other is FeaturedFilter &&
      other.country == country &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(country, origin);
}

/// A ordem e os filtros dos finais em destaque.
abstract final class FeaturedRules {
  /// Os finais prontos para a lista: os de torneio em andamento primeiro, os
  /// ainda não jogados antes dos jogados, e dentro disso os mais recentes.
  static List<FeaturedItem> items(
    FeaturedCatalog catalog,
    Set<String> played, {
    required DateTime now,
  }) {
    final items = [
      for (final each in catalog.finals)
        FeaturedItem(
          endgame: each,
          tournament: catalog.tournament(each.tournamentId),
          played: played.contains(each.id),
          isNew: !played.contains(each.id) && each.isNew(now),
        ),
    ];
    final order = {for (final (i, item) in items.indexed) item.id: i};
    items.sort((a, b) {
      final live = _rank(b, now).compareTo(_rank(a, now));
      if (live != 0) return live;
      final unplayed = (a.played ? 1 : 0).compareTo(b.played ? 1 : 0);
      if (unplayed != 0) return unplayed;
      final aDate = a.endgame.publishedOn;
      final bDate = b.endgame.publishedOn;
      if (aDate != null && bDate != null) {
        final byDate = bDate.compareTo(aDate);
        if (byDate != 0) return byDate;
      } else if (aDate != null || bDate != null) {
        return aDate == null ? 1 : -1;
      }
      return order[a.id]!.compareTo(order[b.id]!);
    });
    return items;
  }

  static int _rank(FeaturedItem item, DateTime now) =>
      item.tournament?.isOngoing(now) ?? false ? 1 : 0;

  /// O que passa pelo [filter]: o país é o do torneio.
  static List<FeaturedItem> filtered(
    List<FeaturedItem> items,
    FeaturedFilter filter,
  ) => [
    for (final item in items)
      if ((filter.origin == null || item.endgame.origin == filter.origin) &&
          (filter.country == null ||
              item.tournament?.country == filter.country))
        item,
  ];

  /// Os torneios em andamento (do país do filtro), para o topo da lista.
  /// Com a origem diferente de torneio, nenhum.
  static List<FeaturedTournament> ongoing(
    FeaturedCatalog catalog,
    FeaturedFilter filter, {
    required DateTime now,
  }) {
    final origin = filter.origin;
    if (origin != null && origin != FeaturedOrigin.tournament) return const [];
    return [
      for (final each in catalog.tournaments)
        if (each.isOngoing(now) &&
            (filter.country == null || each.country == filter.country))
          each,
    ];
  }

  /// Os países que têm torneio com final, em ordem de código.
  static List<String> countries(FeaturedCatalog catalog) {
    final used = {for (final each in catalog.finals) each.tournamentId};
    return {
      for (final tournament in catalog.tournaments)
        if (used.contains(tournament.id) && tournament.country != null)
          tournament.country!,
    }.toList()..sort();
  }

  /// O que a tela inicial destaca: o primeiro da lista, se houver.
  static FeaturedItem? home(List<FeaturedItem> items) =>
      items.isEmpty ? null : items.first;
}
