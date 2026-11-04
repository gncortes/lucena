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

/// A ordem e a separação dos finais em destaque.
abstract final class FeaturedRules {
  /// Os finais prontos para a lista: os de torneio em andamento primeiro, os
  /// ainda não jogados antes dos jogados, os do país do perfil ([country])
  /// antes dos outros, e dentro disso os mais recentes. Todos os finais
  /// aparecem para todos: o país só muda a ordem.
  static List<FeaturedItem> items(
    FeaturedCatalog catalog,
    Set<String> played, {
    required DateTime now,
    String? country,
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
      final local = _local(b, country).compareTo(_local(a, country));
      if (local != 0) return local;
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

  static int _local(FeaturedItem item, String? country) =>
      country != null && item.tournament?.country == country ? 1 : 0;

  /// "Finais recentes": publicados nos últimos [recentDays] dias. O resto
  /// (e o final sem data) é "Finais históricos".
  static bool isRecent(FeaturedItem item, DateTime now) {
    final published = item.endgame.publishedOn;
    if (published == null) return false;
    final age = now.difference(published);
    return !age.isNegative && age < const Duration(days: recentDays);
  }

  /// Quantos dias depois de publicado um final ainda é recente.
  static const recentDays = 30;

  /// Os finais recentes, na ordem de [items].
  static List<FeaturedItem> recent(List<FeaturedItem> items, DateTime now) => [
    for (final item in items)
      if (isRecent(item, now)) item,
  ];

  /// Os finais históricos, na ordem de [items].
  static List<FeaturedItem> historic(List<FeaturedItem> items, DateTime now) =>
      [
        for (final item in items)
          if (!isRecent(item, now)) item,
      ];

  /// Os torneios em andamento, para o topo da lista.
  static List<FeaturedTournament> ongoing(
    FeaturedCatalog catalog, {
    required DateTime now,
  }) => [
    for (final each in catalog.tournaments)
      if (each.isOngoing(now)) each,
  ];

  /// O que a tela inicial destaca: o primeiro da lista, se houver.
  static FeaturedItem? home(List<FeaturedItem> items) =>
      items.isEmpty ? null : items.first;
}
