import 'package:lucena/data/repositories/featured/featured_alerts_repository.dart';
import 'package:lucena/data/repositories/featured/featured_progress_repository.dart';
import 'package:lucena/data/repositories/featured/featured_repository.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/game_setup.dart';

/// Por padrão não há finais em destaque: as outras telas não mudam.
class FakeFeaturedRepository implements FeaturedRepository {
  FakeFeaturedRepository([this.value = FeaturedCatalog.empty]);

  FeaturedCatalog value;

  @override
  Future<FeaturedCatalog> catalog() async => value;
}

class FakeFeaturedProgressRepository implements FeaturedProgressRepository {
  final playedIds = <String>{};
  final choices = <String, FeaturedChoice>{};

  @override
  Future<Set<String>> played() async => {...playedIds};

  @override
  Future<void> markPlayed(String id) async => playedIds.add(id);

  @override
  Future<FeaturedChoice?> choice(String id) async => choices[id];

  @override
  Future<void> saveChoice(String id, FeaturedChoice choice) async =>
      choices[id] = choice;
}

/// Um canal de aviso que existe, para testar o interruptor.
class FakeFeaturedAlertsRepository implements FeaturedAlertsRepository {
  FakeFeaturedAlertsRepository({this.available = true});

  @override
  final bool available;
  var all = false;
  final tournaments = <String>{};

  @override
  Future<bool> enabled() async => all;

  @override
  Future<void> setEnabled({required bool value}) async => all = value;

  @override
  Future<bool> tournamentEnabled(String tournamentId) async =>
      tournaments.contains(tournamentId);

  @override
  Future<void> setTournamentEnabled(
    String tournamentId, {
    required bool value,
  }) async {
    value ? tournaments.add(tournamentId) : tournaments.remove(tournamentId);
  }
}

/// Três finais em dois torneios: um em andamento em 1/1/2026 e outro passado.
FeaturedCatalog sampleFeaturedCatalog() => FeaturedCatalog(
  tournaments: [
    FeaturedTournament(
      id: 'old',
      name: 'Torneio Antigo',
      nameEn: 'Old Tournament',
      year: 1959,
      country: 'US',
      summary: const LocalizedText({'pt': 'Resumo antigo.', 'en': 'Old.'}),
    ),
    FeaturedTournament(
      id: 'live',
      name: 'Torneio ao Vivo',
      year: 2026,
      place: 'Oslo',
      country: 'NO',
      startsOn: DateTime(2025, 12, 28),
      endsOn: DateTime(2026, 1, 5),
      summary: const LocalizedText({'pt': 'Acontece agora.', 'en': 'Now.'}),
      links: [
        FeaturedLink(
          kind: FeaturedLinkKind.results,
          url: Uri.parse('https://example.org/results'),
        ),
        FeaturedLink(
          kind: FeaturedLinkKind.broadcast,
          url: Uri.parse('https://example.org/live'),
        ),
      ],
    ),
  ],
  finals: [
    FeaturedEndgame(
      id: 'a',
      kind: FeaturedKind.play,
      origin: FeaturedOrigin.historical,
      theme: FeaturedTheme.escapedWin,
      fen: '8/1p6/8/8/2P5/1K1k4/1P6/8 b - - 6 55',
      goal: PositionGoal.draw,
      white: const FeaturedPlayer(name: 'Branco A', country: 'US'),
      black: const FeaturedPlayer(name: 'Preto A', country: 'US'),
      tournamentId: 'old',
      result: '1-0',
      publishedOn: DateTime(2025, 6, 1),
      suggested: const FeaturedChoice(opponent: OpponentKind.maia, level: 1600),
      title: const LocalizedText({'pt': 'Final A', 'en': 'Final A'}),
      hook: const LocalizedText({'pt': 'Gancho A', 'en': 'Hook A'}),
      whatHappened: const LocalizedText({'pt': '55...b6?', 'en': '55...b6?'}),
      lessonId: 'pawns.keySquares',
      similarCategory: 'pawn',
    ),
    FeaturedEndgame(
      id: 'b',
      kind: FeaturedKind.findMove,
      origin: FeaturedOrigin.tournament,
      theme: FeaturedTheme.resourcefulDefense,
      fen: '2k5/8/8/8/1PK5/8/8/8 b - - 1 57',
      goal: PositionGoal.draw,
      white: const FeaturedPlayer(name: 'Branco B', title: 'GM', fideId: 1),
      black: const FeaturedPlayer(name: 'Preto B', country: 'NO'),
      tournamentId: 'live',
      round: 3,
      result: '1/2-1/2',
      publishedOn: DateTime(2025, 12, 30),
      solutions: const ['c8b8'],
      suggested: const FeaturedChoice(opponent: OpponentKind.stockfish),
      title: const LocalizedText({'pt': 'Final B', 'en': 'Final B'}),
      hook: const LocalizedText({'pt': 'Gancho B', 'en': 'Hook B'}),
      hint: const LocalizedText({'pt': 'Dica B', 'en': 'Hint B'}),
    ),
    FeaturedEndgame(
      id: 'c',
      kind: FeaturedKind.play,
      origin: FeaturedOrigin.video,
      theme: FeaturedTheme.perfectConversion,
      fen: '8/8/5k1p/8/6PP/5K2/8/8 w - - 2 55',
      goal: PositionGoal.win,
      white: const FeaturedPlayer(name: 'Branco C'),
      black: const FeaturedPlayer(name: 'Preto C'),
      playerCanChange: true,
      suggested: const FeaturedChoice(
        opponent: OpponentKind.maia,
        level: 1400,
        clock: '180+0',
      ),
      title: const LocalizedText({'pt': 'Final C', 'en': 'Final C'}),
      hook: const LocalizedText({'pt': 'Gancho C', 'en': 'Hook C'}),
    ),
  ],
);
