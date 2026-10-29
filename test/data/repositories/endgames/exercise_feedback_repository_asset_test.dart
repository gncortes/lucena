import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';

class _Assets extends AssetService {
  _Assets(this.files);
  final Map<String, String> files;
  int reads = 0;
  @override
  Future<String> loadString(String path) async {
    reads++;
    final value = files[path];
    if (value == null) throw StateError('Missing fixture');
    return value;
  }
}

void main() {
  const lesson = 'lesson.example';
  const fen = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
  test('fixture sintética: e09/d2d3 pt/en exatos, tipo exercício e lição, cache por aula', () async {
    final path = AssetExerciseFeedbackRepository.assetPath(lesson);
    final data = jsonEncode({
      'lesson': lesson,
      'rows': [
        for (final kind in ['exercise', 'move'])
          {
            'kind': kind,
            'id': kind == 'exercise' ? 'e09' : 'step',
            'turn': 1,
            'fen': fen,
            'uci': 'd2d3',
            'pt': 'Explicação sintética.',
            'en': 'Synthetic explanation.',
          },
      ],
    });
    final rows = (jsonDecode(data)['rows'] as List)
        .cast<Map<String, dynamic>>();
    final expected = rows.singleWhere(
      (row) =>
          row['kind'] == 'exercise' &&
          row['id'] == 'e09' &&
          row['fen'] == fen &&
          row['uci'] == 'd2d3',
    );
    final assets = _Assets({path: data});
    final repository = AssetExerciseFeedbackRepository(assets);
    for (final language in ['pt', 'en']) {
      expect(
        await repository.find(
          lessonId: lesson,
          exerciseId: 'e09',
          kind: 'exercise',
          turn: 1,
          fen: fen,
          uci: 'd2d3',
          language: language,
        ),
        expected[language],
      );
    }
    expect(
      await repository.find(
        lessonId: lesson,
        exerciseId: 'e10',
        kind: 'exercise',
        turn: 1,
        fen: fen,
        uci: 'd2d3',
        language: 'pt',
      ),
      isNull,
    );
    final move = rows.firstWhere((row) => row['kind'] == 'move');
    expect(
      await repository.find(
        lessonId: lesson,
        exerciseId: move['id'],
        kind: move['kind'],
        turn: move['turn'],
        fen: move['fen'],
        uci: move['uci'],
        language: 'pt',
      ),
      move['pt'],
    );
    // Every frozen row is reachable through its full authored identity.
    for (final row in rows) {
      for (final language in ['pt', 'en']) {
        expect(
          await repository.find(
            lessonId: lesson,
            exerciseId: row['id'],
            kind: row['kind'],
            turn: row['turn'],
            fen: row['fen'],
            uci: row['uci'],
            language: language,
          ),
          row[language],
        );
      }
    }
    for (final change in [
      (kind: 'move', turn: 1, fen: fen),
      (kind: 'exercise', turn: 2, fen: fen),
      (kind: 'exercise', turn: 1, fen: fen.replaceFirst('0 1', '1 1')),
      (kind: 'exercise', turn: 1, fen: fen.replaceFirst('0 1', '0 2')),
      (kind: 'exercise', turn: 1, fen: fen.replaceFirst(' w ', ' b ')),
    ]) {
      expect(
        await repository.find(
          lessonId: lesson,
          exerciseId: 'e09',
          kind: change.kind,
          turn: change.turn,
          fen: change.fen,
          uci: 'd2d3',
          language: 'pt',
        ),
        isNull,
      );
    }
    expect(assets.reads, 1);
  });

  test(
    'aula ausente, arquivo inválido ou identidade incorreta retorna fallback',
    () async {
      for (final data in [
        null,
        'invalid json',
        '{"lesson":"other","rows":[]}',
      ]) {
        final repository = AssetExerciseFeedbackRepository(
          _Assets({AssetExerciseFeedbackRepository.assetPath(lesson): ?data}),
        );
        expect(
          await repository.find(
            lessonId: lesson,
            exerciseId: 'e09',
            kind: 'exercise',
            turn: 1,
            fen: fen,
            uci: 'd2d3',
            language: 'pt',
          ),
          isNull,
        );
      }
    },
  );
}
