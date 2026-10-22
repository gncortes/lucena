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

    test('filtra por país do torneio e por origem', () {
      final items = FeaturedRules.items(catalog, {}, now: now);
      expect(
        [
          for (final i in FeaturedRules.filtered(
            items,
            const FeaturedFilter(country: 'US'),
          ))
            i.id,
        ],
        ['a'],
      );
      expect(
        [
          for (final i in FeaturedRules.filtered(
            items,
            const FeaturedFilter(origin: FeaturedOrigin.video),
          ))
            i.id,
        ],
        ['c'],
      );
      expect(FeaturedRules.filtered(items, FeaturedFilter.none), hasLength(3));
    });

    test('torneios em andamento seguem os filtros', () {
      expect(
        FeaturedRules.ongoing(catalog, FeaturedFilter.none, now: now),
        hasLength(1),
      );
      expect(
        FeaturedRules.ongoing(
          catalog,
          const FeaturedFilter(country: 'US'),
          now: now,
        ),
        isEmpty,
      );
      expect(
        FeaturedRules.ongoing(
          catalog,
          const FeaturedFilter(origin: FeaturedOrigin.video),
          now: now,
        ),
        isEmpty,
      );
    });

    test('países vêm só de torneios com final, em ordem', () {
      expect(FeaturedRules.countries(catalog), ['NO', 'US']);
    });

    test('a home mostra o primeiro, ou nada', () {
      final items = FeaturedRules.items(catalog, {}, now: now);
      expect(FeaturedRules.home(items)!.id, 'b');
      expect(FeaturedRules.home(const []), isNull);
    });

    test('filtro compara por valor e copia', () {
      const filter = FeaturedFilter(country: 'US');
      expect(filter.isActive, isTrue);
      expect(filter, const FeaturedFilter(country: 'US'));
      expect(filter.copyWith(clearCountry: true).isActive, isFalse);
    });
  });
}
