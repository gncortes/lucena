import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<String> _ids(Object? list) => [
  for (final id in (list ?? const []) as List) id as String,
];

/// `review.json` (E1.08, QA r1): "failed" e "passed" só guardam aulas que ainda
/// estão em revisão ("lessons"), e todo id existe no índice. Aula liberada que
/// sobra em "failed" aparece com o selo "Reprovada" numa instalação nova.
void main() {
  final review = _json('assets/lessons/endgames/review.json');
  final index = _json('assets/lessons/endgames/index.json');
  final inIndex = {
    for (final m in index['modules'] as List) ...(m as Map)['lessons'] as List,
  };
  final inReview = _ids(review['lessons']);

  test('todo id de "failed" e de "passed" está em "lessons"', () {
    for (final key in ['failed', 'passed']) {
      for (final id in _ids(review[key])) {
        expect(inReview, contains(id), reason: '$key: $id saiu da revisão');
      }
    }
  });

  test('todo id das listas existe no índice das aulas', () {
    for (final key in ['lessons', 'failed', 'passed']) {
      for (final id in _ids(review[key])) {
        expect(inIndex, contains(id), reason: '$key: $id não está no índice');
      }
    }
  });

  test('a Oposição liberada (T76) não tem selo de reprovada', () {
    expect(_ids(review['failed']), isNot(contains('pawns.keySquares')));
  });
}
