import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/endgame_progress_migration.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// A Oposição em três lições (T76): casas-chave e oposição, oposição distante
/// e lances de espera, cada capítulo com o roteiro dele.
void main() {
  const keySquares = EndgameProgressMigration.keySquaresId;
  const distant = EndgameProgressMigration.firstId;
  const waiting = EndgameProgressMigration.secondId;
  const ids = [keySquares, distant, waiting];
  final lessons = {
    for (final id in ids) id: _json('assets/lessons/endgames/$id.json'),
  };
  List<String> parts(String id) => [
    for (final p in lessons[id]!['parts'] as List) (p as Map)['id'] as String,
  ];
  List<Map<String, dynamic>> exercises(String id) => [
    for (final e in lessons[id]!['exercises'] as List)
      e as Map<String, dynamic>,
  ];

  test('o índice lista as três lições, uma depois da outra', () {
    final index = _json('assets/lessons/endgames/index.json');
    final pawns = [
      for (final m in index['modules'] as List)
        if ((m as Map)['id'] == 'pawns') ...(m['lessons'] as List),
    ];
    expect(pawns.indexOf(distant), pawns.indexOf(keySquares) + 1);
    expect(pawns.indexOf(waiting), pawns.indexOf(distant) + 1);
    final review = _json('assets/lessons/endgames/review.json');
    // Liberadas pelo Gabriel (T76): as três saem do selo "em revisão".
    for (final id in ids) {
      expect(review['lessons'], isNot(contains(id)));
    }
  });

  test('os capítulos de cada lição, na ordem do plano', () {
    expect(parts(keySquares), ['keySquares', 'opposition', 'diagonal']);
    expect(parts(distant), [
      'distant',
      'lateral',
      'capablanca',
      'edge',
      'means',
    ]);
    expect(parts(waiting), [
      'reserve',
      'waiting',
      'secondReserve',
      'fixedTarget',
    ]);
    expect(
      parts(keySquares),
      containsAll(EndgameProgressMigration.keySquaresChapters),
    );
    expect({
      ...parts(keySquares),
      ...parts(distant),
      ...parts(waiting),
    }, hasLength(12));
  });

  test('cada capítulo aponta o roteiro dele, sem passos antigos', () {
    for (final id in ids) {
      for (final part in lessons[id]!['parts'] as List) {
        final p = part as Map;
        expect(
          p['roteiro'],
          'assets/lessons/roteiros/$id/${p['id']}.json',
          reason: '$id ${p['id']}',
        );
        expect(p['steps'], isEmpty, reason: '$id ${p['id']}');
      }
    }
    expect(
      File('assets/lessons/roteiros/$distant/distant.json').existsSync(),
      isTrue,
    );
  });

  test('exercícios com ids distintos em cada lição, ideia na lição certa', () {
    for (final id in ids) {
      final list = exercises(id);
      expect({for (final e in list) e['id']}, hasLength(list.length));
      final stars = [for (final e in list) e['stars'] as int];
      expect(
        lessons[id]!['maxScore'],
        stars.reduce((x, y) => x + y),
        reason: id,
      );
    }
    expect([for (final e in exercises(waiting)) e['id']], contains('e17'));
    expect([
      for (final e in exercises(distant)) e['id'],
    ], isNot(contains('e17')));
  });

  test('a nota mínima vale para os exercícios que aparecem', () {
    for (final id in ids) {
      final hidden = VisibleLessons.hiddenExercises[id] ?? const <String>{};
      final visible = exercises(id).where((e) => !hidden.contains(e['id']));
      final max = visible.fold<int>(0, (sum, e) => sum + (e['stars'] as int));
      expect(lessons[id]!['passScore'] as int, lessThan(max), reason: id);
      expect(lessons[id]!['passScore'] as int, greaterThan(0), reason: id);
    }
    for (final entry in VisibleLessons.hiddenExercises.entries) {
      expect([
        for (final e in exercises(entry.key)) e['id'],
      ], containsAll(entry.value));
    }
  });

  test('cada exercício tem enunciado, dica, solução e resposta em pt e en', () {
    for (final id in ids) {
      for (final lang in ['pt', 'en']) {
        final t = _json('assets/lessons/$lang/endgames/$id.json');
        expect(t['title'], isNotEmpty);
        for (final e in exercises(id)) {
          final key = 'ex.${e['id']}';
          for (final suffix in ['', '.hint', '.solution']) {
            expect(t['$key$suffix'], isNotNull, reason: '$lang $key$suffix');
          }
        }
        for (final p in parts(id)) {
          expect(t['part.$p.title'], isNotNull, reason: '$lang $id part.$p');
        }
      }
    }
  });

  test('os nós de habilidade seguem a ordem das lições', () {
    final skills = _json('assets/placement/skills.json');
    final nodes = {
      for (final n in skills['nodes'] as List) (n as Map)['id']: n,
    };
    expect((nodes[distant] as Map)['requires'], [keySquares]);
    expect((nodes[waiting] as Map)['requires'], [distant]);
    for (final id in ids) {
      expect(lessons[id]!['skills'], [id]);
    }
  });
}
