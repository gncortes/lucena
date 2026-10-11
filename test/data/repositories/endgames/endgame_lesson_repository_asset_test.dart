import 'dart:convert';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';

import '../../../../testing/fakes/fake_school_repositories.dart';

/// Um pacote de assets na memória.
class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final file = files[key];
    if (file == null) throw FlutterError('não há $key');
    return ByteData.sublistView(utf8.encoder.convert(file));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final file = files[key];
    if (file == null) throw FlutterError('não há $key');
    return file;
  }
}

const _lesson = {
  'id': 'rook.lucena',
  'module': 'rook',
  'steps': [
    {
      'type': 'talk',
      'id': 'intro',
      'fen': '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
    },
    {
      'type': 'move',
      'id': 'bridge',
      'fen': '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
      'goal': 'win',
      'line': [
        {
          'accept': ['c1c4'],
          'reply': 'a2a1',
        },
        {
          'accept': ['b8c7'],
        },
      ],
    },
  ],
  'exercises': [
    {
      'id': 'e01',
      'stars': 2,
      'fen': '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
      'goal': 'win',
      'origin': 'own',
      'line': [
        {
          'accept': ['c1c4'],
        },
      ],
    },
  ],
  'passScore': 1,
  'maxScore': 2,
  'keyPositions': [
    {'id': 'classic', 'fen': '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1', 'ref': 'b1'},
  ],
  'practice': {
    'fen': '8/1R6/6P1/8/6r1/7k/8/7K w - - 0 1',
    'goal': 'win',
    'positionId': 'rookPawn.rookPawnVsRook.0001',
  },
  'references': [
    {
      'id': 'b1',
      'kind': 'book',
      'author': 'A',
      'title': 'T',
      'publisher': 'P',
      'year': 2008,
    },
  ],
};

void main() {
  AssetEndgameLessonRepository repository() => AssetEndgameLessonRepository(
    AssetService(
      _Bundle({
        AssetEndgameLessonRepository.indexPath: jsonEncode({
          'modules': [
            {
              'id': 'rook',
              'lessons': ['rook.lucena'],
            },
          ],
        }),
        AssetEndgameLessonRepository.lessonPath('rook.lucena'): jsonEncode(
          _lesson,
        ),
        AssetEndgameLessonRepository.textsPath('en', 'rook.lucena'): jsonEncode(
          {
            'title': 'The Lucena position',
            'step.intro': 'Intro',
            'step.bridge': 'Bridge',
            'step.bridge.hint': 'Hint',
            'ex.e01': 'Exercise',
            'history': 'History',
          },
        ),
        AssetEndgameLessonRepository.textsPath('pt', 'rook.lucena'): jsonEncode(
          {'title': 'A posição de Lucena', 'step.intro': 'Introdução'},
        ),
      }),
    ),
    school: FakeLessonRepository(),
  );

  test(
    'lê o índice e a aula com os passos, exercícios e referências',
    () async {
      final trail = await repository().trail();
      expect(trail.modules.single.id, 'rook');
      final lesson = trail.lessons.single;
      expect(lesson.id, 'rook.lucena');
      expect(lesson.lesson.steps, hasLength(2));
      final bridge = lesson.lesson.steps[1] as MoveStep;
      expect(bridge.line.first.accept, {'c1c4'});
      expect(bridge.line.first.reply, 'a2a1');
      expect(lesson.exercises.single.stars, 2);
      expect(lesson.exercises.single.line.single.accept, {'c1c4'});
      expect(lesson.maxScore, 2);
      expect(lesson.passScore, 1);
      expect(lesson.keyPositions.single.ref, 'b1');
      expect(lesson.practice.positionId, 'rookPawn.rookPawnVsRook.0001');
      expect(lesson.practice.goal, PositionGoal.win);
      final book = lesson.references.single;
      expect(book.kind, 'book');
      expect(book['year'], '2008');
      expect(book.title, 'T');
    },
  );

  test('as falas ganham o prefixo da aula, e o idioma cai no inglês', () async {
    final texts = await repository().texts('pt');
    expect(texts.lessonTitle('rook.lucena'), 'A posição de Lucena');
    expect(texts.step('rook.lucena', 'intro'), 'Introdução');
    // Falta em português: vem do inglês.
    expect(texts.step('rook.lucena', 'bridge'), 'Bridge');
    expect(texts.hint('rook.lucena', 'bridge'), 'Hint');
    expect(texts.say('rook.lucena.ex.e01'), 'Exercise');
    expect(texts.say('rook.lucena.history'), 'History');
    // As falas comuns da escola ficam por baixo.
    expect(texts.say('coach.praise'), 'Excellent.');
  });

  test('passo de fala com `side` mostra o tabuleiro desse lado, mesmo com o '
      'outro lado jogando no FEN', () {
    final lesson = AssetLessonRepository.parseLesson({
      'id': 'x',
      'steps': [
        {
          'type': 'talk',
          'id': 'a',
          'fen': '1k6/1r6/2K5/Q7/8/8/8/8 b - - 0 1',
          'side': 'white',
        },
        {'type': 'talk', 'id': 'b', 'fen': '1k6/1r6/2K5/Q7/8/8/8/8 b - - 0 1'},
      ],
    });
    expect(lesson.steps[0].side, Side.white);
    expect(lesson.steps[1].side, Side.black);
  });

  test('`ref` do passo é lido em todo tipo de passo e aponta a referência '
      'da aula; sem `ref`, nulo', () {
    const fen = '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1';
    final lesson = AssetEndgameLessonRepository.parseLesson({
      ..._lesson,
      'parts': [
        {
          'id': 'p1',
          'steps': [
            {'type': 'think', 'id': 't', 'fen': fen, 'ref': 'g1'},
            {'type': 'talk', 'id': 'a', 'fen': fen, 'ref': 'g1'},
            {
              'type': 'demo',
              'id': 'd',
              'fen': fen,
              'ref': 'g1',
              'line': [
                {'uci': 'c1c4'},
              ],
            },
            {
              'type': 'move',
              'id': 'm',
              'fen': fen,
              'ref': 'g1',
              'line': [
                {
                  'accept': ['c1c4'],
                },
              ],
            },
            {'type': 'play', 'id': 'p', 'fen': fen, 'ref': 'g1'},
            {'type': 'talk', 'id': 'none', 'fen': fen},
          ],
        },
      ],
      'references': [
        ...(_lesson['references']! as List),
        {
          'id': 'g1',
          'kind': 'game',
          'white': 'Lucena',
          'black': 'X',
          'event': 'Y',
          'year': 1497,
          'url': 'https://lichess.org/analysis/pgn/1.e4#1',
        },
      ],
    });
    final steps = lesson.lesson.steps;
    expect(
      [for (final step in steps) step.ref],
      ['g1', 'g1', 'g1', 'g1', 'g1', null],
    );
    final reference = lesson.reference(steps.first.ref);
    expect(reference?.kind, 'game');
    expect(reference?.url, 'https://lichess.org/analysis/pgn/1.e4#1');
    expect(lesson.reference('b1')?.url, isNull);
    expect(lesson.reference(null), isNull);
    expect(lesson.reference('nada'), isNull);
  });
}
