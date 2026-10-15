import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/positions/positions_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/use_cases/position_validation.dart';

/// Lê os arquivos do próprio projeto, como o app lê os dele.
class _ProjectBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  late AssetPositionsRepository repository;

  setUp(() {
    repository = AssetPositionsRepository(AssetService(_ProjectBundle()));
  });

  test('o catálogo do app tem as categorias dos finais de iniciante', () async {
    final catalog = await repository.catalog();

    // Os mates de dois bispos e de bispo e cavalo entraram pelo speedrun.
    expect(catalog.map((c) => c.key), [
      'basic',
      'pawn',
      'bishop',
      'knightBishop',
      'rookPawn',
      'queen',
    ]);
    final total = catalog.fold(0, (sum, c) => sum + c.count(GoalFilter.all));
    // 55 de iniciante e as ligadas às lições (tools/lesson_positions.py).
    expect(total, greaterThanOrEqualTo(55));
  });

  test('toda posição do catálogo é jogável e foi conferida', () async {
    final catalog = await repository.catalog();
    for (final category in catalog) {
      for (final sub in category.subcategories) {
        for (final position in await repository.bySubcategory(sub.key)) {
          final check = PositionValidation.check(position.fen);
          expect(check.problem, isNull, reason: position.id);
          expect(position.verified, isTrue, reason: position.id);
        }
      }
    }
  });

  test('as contagens por objetivo batem com as posições', () async {
    final catalog = await repository.catalog();
    final sub = catalog
        .expand((c) => c.subcategories)
        .firstWhere((s) => s.key == 'pawnVsKing');
    final positions = await repository.bySubcategory('pawnVsKing');

    expect(
      sub.winCount,
      positions.where((p) => p.goal == PositionGoal.win).length,
    );
    expect(
      sub.drawCount,
      positions.where((p) => p.goal == PositionGoal.draw).length,
    );
    expect(sub.drawCount, greaterThan(0));
  });

  test('busca pelo id e informa o mate quando a fonte informa', () async {
    final position = await repository.byId('basic.queen.0001');

    expect(position?.fen, '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1');
    expect(position?.goal, PositionGoal.win);
    expect(position?.mateIn, 8);
    expect(position?.number, 1);
    expect(await repository.byId('nao.existe.0001'), isNull);
  });

  group('ligações às lições (lesson_links.json)', () {
    const p1 = 'pawns.distantOpposition';
    const p2 = 'pawns.waitingMoves';

    Future<List<EndgamePosition>> all() async => [
      for (final category in await repository.catalog())
        for (final sub in category.subcategories)
          ...await repository.bySubcategory(sub.key),
    ];

    test('as lições com posição vêm na ordem da escola', () async {
      expect(await repository.lessonsWithLinks(), [p1, p2]);
    });

    test('toda ligação aponta para posição do catálogo, de peão', () async {
      final links =
          jsonDecode(
                File(AssetPositionsRepository.linksPath).readAsStringSync(),
              )['links']
              as Map<String, dynamic>;
      expect(links, isNotEmpty);
      for (final id in links.keys) {
        final position = await repository.byId(id);
        expect(position, isNotNull, reason: id);
        expect(position!.category, 'pawn', reason: id);
        expect(position.links, isNotEmpty, reason: id);
      }
    });

    test('as ligadas têm seção de material e dificuldade de 1 a 3', () async {
      final linked = [
        for (final p in await all())
          if (p.links.isNotEmpty) p,
      ];
      expect(
        linked.where((p) => p.links.any((l) => l.lessonId == p1)),
        isNotEmpty,
      );
      expect(
        linked.where((p) => p.links.any((l) => l.lessonId == p2)),
        isNotEmpty,
      );
      for (final position in linked) {
        expect(
          position.section,
          matches(RegExp(r'^KP*vKP*$')),
          reason: position.id,
        );
        expect(
          position.difficulty,
          inInclusiveRange(1, 3),
          reason: position.id,
        );
        for (final link in position.links) {
          expect(
            link.ply == 0,
            link.relation == LessonRelation.base,
            reason: position.id,
          );
        }
      }
    });

    test('a contagem com o filtro de lição bate com as posições', () async {
      const filter = CatalogFilter(goal: GoalFilter.draw, lessons: {p1, p2});
      final shown = (await all()).where(filter.accepts).length;
      final counted = (await repository.catalog()).fold(
        0,
        (sum, c) => sum + c.countFor(filter),
      );
      expect(counted, shown);
    });

    test('nenhuma ligada repete posição de lição', () async {
      final lessons = <String>{};
      final fen = RegExp(
        r'[pnbrqkPNBRQK1-8]{1,8}(?:/[pnbrqkPNBRQK1-8]{1,8}){7} [wb]',
      );
      for (final file in Directory(
        'assets/lessons',
      ).listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.json')) {
          lessons.addAll(
            fen.allMatches(file.readAsStringSync()).map((m) => m[0]!),
          );
        }
      }
      for (final position in await all()) {
        if (position.links.isEmpty) continue;
        final here = position.fen.split(' ').take(2).join(' ');
        expect(lessons, isNot(contains(here)), reason: position.id);
      }
    });
  });
}
