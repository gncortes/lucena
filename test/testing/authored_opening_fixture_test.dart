import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';

import '../../testing/script_fixture.dart';
import '../../testing/training/authored_opening_fixture.dart';

class _Reader extends LessonContentReader {
  _Reader(this.files);
  final Map<String, Object> files;
  @override
  Future<String> read(String path) async => jsonEncode(files[path]!);
}

void main() {
  test(
    'copies the authored example through its source part, not course part',
    () async {
      final example = {
        'id': 'original',
        'fen': exampleOneFen,
        'vira': true,
        'linha': [
          {'fen': afterKe4, 't': 'source.text', 'lance': 'd3e4'},
        ],
        'opaque': {
          'preserve': ['source', 'fields'],
        },
      };
      const path = 'assets/lessons/roteiros/pilares.ab1/london1.json';
      final resources = await authoredOpeningFixture(
        LessonContentAssets(
          reader: _Reader({
            'assets/lessons/endgames/pilares.ab1.json': {
              'parts': [
                {'id': 'london1', 'roteiro': path},
              ],
            },
            path: {
              'licao': 'pilares.ab1',
              'parte': 'london1',
              'etapas': [
                {
                  'id': 'ideia',
                  'exemplos': [example],
                },
              ],
            },
          }),
        ),
        TrainingResources(
          lessons: [
            const TrainingLesson(
              id: 'pilares.ab1.london1',
              kind: TrainingLessonKind.opening,
              title: 'Source title',
              groupId: 'pilares.ab1',
              partId: 'curriculum-part-1',
            ),
          ],
        ),
      );
      final result = resources.openings['pilares.ab1.london1']!.single;
      expect(result.id, 'ideia.original');
      expect(result.source, path);
      expect(result.fen, exampleOneFen);
      expect(result.black, isTrue);
      expect(result.example, example);
      expect(result.mock, isFalse);
    },
  );
}
