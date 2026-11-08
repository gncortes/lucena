import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/featured_rules.dart';

import '../../testing/fakes/fake_featured_repositories.dart';

void main() {
  final catalog = sampleFeaturedCatalog();
  final now = DateTime(2026, 1, 1, 12);

  group('modelo', () {
    test('lê um final e um torneio do JSON', () {
      final parsed = FeaturedCatalog.fromJson({
        'tournaments': [
          {
            'id': 't',
            'name': 'Torneio',
            'name_en': 'Tournament',
            'year': 2020,
            'country': 'BR',
            'startsOn': '2026-01-01',
            'endsOn': '2026-01-03',
            'summary': {'pt': 'a', 'en': 'b'},
            'links': [
              {'kind': 'results', 'url': 'https://example.org/r'},
            ],
          },
        ],
        'finals': [
          {
            'id': 'f',
            'kind': 'findMove',
            'origin': 'online',
            'theme': 'escapedWin',
            'tournament': 't',
            'white': {'name': 'A'},
            'black': {'name': 'B'},
            'fen': '2k5/8/8/8/1PK5/8/8/8 b - - 1 57',
            'goal': 'draw',
            'solutions': ['c8b8'],
            'title': {'pt': 'T', 'en': 'T'},
          },
        ],
      });
      final tournament = parsed.tournament('t')!;
      expect(tournament.nameIn('en'), 'Tournament');
      expect(tournament.nameIn('pt'), 'Torneio');
      expect(tournament.link(FeaturedLinkKind.results), isNotNull);
      expect(tournament.link(FeaturedLinkKind.broadcast), isNull);
      expect(tournament.isOngoing(DateTime(2026, 1, 3, 23)), isTrue);
      expect(tournament.isOngoing(DateTime(2026, 1, 4)), isFalse);
      final endgame = parsed.endgame('f')!;
      expect(endgame.isFindMove, isTrue);
      expect(endgame.userSide, Side.black);
      expect(parsed.finalsOf('t'), hasLength(1));
      expect(parsed.endgame('x'), isNull);
      expect(parsed.tournament(null), isNull);
    });

    test('texto localizado cai no inglês e depois no primeiro', () {
      const text = LocalizedText({'en': 'e', 'fr': 'f'});
      expect(text.of('pt'), 'e');
      expect(const LocalizedText({'fr': 'f'}).of('pt'), 'f');
      expect(const LocalizedText({}).of('pt'), '');
    });

    test('a escolha converte o relógio', () {
      const choice = FeaturedChoice(
        opponent: OpponentKind.maia,
        level: 1400,
        clock: '180+0',
      );
      expect(choice.time, isNotNull);
      expect(
        const FeaturedChoice(opponent: OpponentKind.stockfish).time,
        isNull,
      );
    });
  });

  group('regras', () {
    test('torneio em andamento primeiro, depois não jogados, depois data', () {
      final items = FeaturedRules.items(catalog, {'b'}, now: now);
      // b é do torneio em andamento: vem primeiro mesmo jogado.
      expect([for (final i in items) i.id], ['b', 'a', 'c']);
      final none = FeaturedRules.items(catalog, {}, now: now);
      expect(none.first.id, 'b');
    });

    test('jogados vão para o fim fora do torneio em andamento', () {
      final items = FeaturedRules.items(catalog, {'a'}, now: now);
      expect([for (final i in items) i.id], ['b', 'c', 'a']);
      expect(items.last.played, isTrue);
      expect(items.last.isNew, isFalse);
    });

    test('o país do perfil só muda a ordem, ninguém perde final', () {
      final plain = FeaturedRules.items(catalog, {}, now: now);
      final us = FeaturedRules.items(catalog, {}, now: now, country: 'US');
      expect(us, hasLength(plain.length));
      expect([for (final i in us) i.id], ['b', 'a', 'c']);
      final played = FeaturedRules.items(catalog, {'b'}, now: now);
      expect(played.first.id, 'b');
    });

    test('torneios em andamento', () {
      expect(FeaturedRules.ongoing(catalog, now: now), hasLength(1));
      expect(FeaturedRules.ongoing(catalog, now: DateTime(2030)), isEmpty);
    });

    test('recentes são os dos últimos 30 dias; o resto é histórico', () {
      final items = FeaturedRules.items(catalog, {}, now: now);
      // b: publicado em 30/12/2025 (e torneio em andamento); a: 1/6/2025; c: sem data.
      expect([for (final i in FeaturedRules.recent(items, now)) i.id], ['b']);
      expect(
        [for (final i in FeaturedRules.historic(items, now)) i.id],
        ['a', 'c'],
      );
      expect(
        FeaturedRules.isRecent(items.first, DateTime(2026, 1, 28)),
        isTrue,
      );
      expect(
        FeaturedRules.isRecent(items.first, DateTime(2026, 2, 5)),
        isFalse,
      );
    });

    test('a home mostra o primeiro, ou nada', () {
      final items = FeaturedRules.items(catalog, {}, now: now);
      expect(FeaturedRules.home(items)!.id, 'b');
      expect(FeaturedRules.home(const []), isNull);
    });
  });
}
