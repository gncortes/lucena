import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/endgame_progress_migration.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  const first = EndgameProgressMigration.firstId;
  const second = EndgameProgressMigration.secondId;
  final a = _json('assets/lessons/endgames/$first.json');
  final b = _json('assets/lessons/endgames/$second.json');
  List<String> parts(Map<String, dynamic> l) => [
    for (final p in l['parts'] as List) (p as Map)['id'] as String,
  ];
  List<Map<String, dynamic>> exercises(Map<String, dynamic> l) => [
    for (final e in l['exercises'] as List) e as Map<String, dynamic>,
  ];

  test('o índice lista as duas partes, uma depois da outra', () {
    final index = _json('assets/lessons/endgames/index.json');
    final pawns = [
      for (final m in index['modules'] as List)
        if ((m as Map)['id'] == 'pawns') ...(m['lessons'] as List),
    ];
    expect(pawns.indexOf(second), pawns.indexOf(first) + 1);
    final review = _json('assets/lessons/endgames/review.json');
    expect(review['lessons'], containsAll([first, second]));
  });

  test(
    'os capítulos dividem-se como na migração, mais um recap e um fecho',
    () {
      expect(parts(a), [
        ...[
          'distant', 'diagonal', 'defend', 'lateral', 'capablanca', 'outflank',
          'edge', 'edgeCorner', 'protectPawn', //
        ],
        'wrapUp',
      ]);
      expect(parts(b), ['refresher', ...EndgameProgressMigration.secondParts]);
      expect(
        parts(a).where(EndgameProgressMigration.firstParts.contains).toSet(),
        EndgameProgressMigration.firstParts,
      );
      expect(parts(a).toSet().intersection(parts(b).toSet()), isEmpty);
    },
  );

  test(
    'seis exercícios por parte, em rampa de estrelas, com ids distintos',
    () {
      for (final l in [a, b]) {
        final list = exercises(l);
        expect(list, hasLength(6));
        final stars = [for (final e in list) e['stars'] as int];
        expect(stars, [...stars]..sort(), reason: 'rampa de estrelas');
        expect(l['maxScore'], stars.reduce((x, y) => x + y));
        expect(l['passScore'] as int, lessThan(l['maxScore'] as int));
      }
      final ids = [
        ...exercises(a),
        ...exercises(b),
      ].map((e) => e['id']).toList();
      expect(ids.toSet(), hasLength(12));
      expect([
        for (final e in exercises(b)) e['id'],
      ], containsAll(EndgameProgressMigration.secondExercises));
    },
  );

  test('cada exercício tem enunciado, dica, solução e resposta em pt e en', () {
    for (final (id, l) in [(first, a), (second, b)]) {
      for (final lang in ['pt', 'en']) {
        final t = _json('assets/lessons/$lang/endgames/$id.json');
        expect(t['title'], isNotEmpty);
        for (final e in exercises(l)) {
          final key = 'ex.${e['id']}';
          for (final suffix in ['', '.hint', '.solution']) {
            expect(t['$key$suffix'], isNotNull, reason: '$lang $key$suffix');
          }
          final replies = (e['line'] as List)
              .where((s) => (s as Map).containsKey('reply'))
              .length;
          for (var i = 1; i <= replies; i++) {
            expect(t['$key.r$i'], isNotNull, reason: '$lang $key.r$i');
          }
        }
        for (final p in parts(l)) {
          expect(t['part.$p.title'], isNotNull, reason: '$lang part.$p');
        }
      }
    }
  });

  test('a Parte 2 tem o próprio nó de habilidade, que exige a Parte 1', () {
    final skills = _json('assets/placement/skills.json');
    final nodes = {
      for (final n in skills['nodes'] as List) (n as Map)['id']: n,
    };
    final node = nodes[second] as Map;
    expect(node['requires'], [first]);
    expect(b['skills'], [second]);
    expect(a['skills'], [first]);
  });
}
