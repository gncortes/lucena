import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/training_endgame_content.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';

import '../../../../testing/fakes/fake_school_repositories.dart';

const index = 'assets/courses/private/index.json';
const chapter = 'assets/lessons/endgames/private.c1.json';
const script = 'assets/lessons/roteiros/private.c1/topic.json';

class _Assets extends AssetService {
  final files = <String, String>{};
  final reads = <String>[];
  Object scope = Object();
  String? unavailable;
  final offline = <String>{};
  Completer<void>? gate;
  @override
  Object get cacheScope => scope;
  @override
  Future<String> loadString(String path) async {
    reads.add(path);
    await gate?.future;
    if (path == unavailable) throw const LessonContentUnavailable();
    if (offline.contains(path)) throw const LessonContentNetworkUnavailable();
    return files[path] ?? (throw const LessonContentNotFound());
  }
}

void main() {
  late _Assets assets;
  late TrainingEndgameContent content;
  setUp(() {
    assets = _Assets();
    assets.files.addAll({
      index: jsonEncode({
        'partes': [
          {
            'id': 'part1',
            'capitulos': [
              {
                'id': 'private.c1',
                'aulas': [
                  {'id': 'private.c1', 'tipo': 'teste'},
                ],
              },
            ],
          },
        ],
      }),
      chapter: jsonEncode({
        'id': 'private.c1',
        'module': 'part1',
        'parts': [
          {'id': 'topic', 'roteiro': script, 'steps': <Object>[]},
        ],
        'exercises': [
          {
            'id': 'e1',
            'stars': 3,
            'fen': '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
            'goal': 'win',
            'line': [
              {
                'accept': ['a1a8'],
              },
            ],
          },
        ],
        'practice': {'fen': '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1'},
        'passScore': 2,
      }),
      script: '{}',
      'assets/lessons/en/endgames/private.c1.json': jsonEncode({
        'title': 'Private title',
        'step.intro': 'Private explanation',
      }),
      'assets/lessons/pt/endgames/private.c1.json': jsonEncode({
        'title': 'Título privado',
      }),
    });
    content = TrainingEndgameContent(
      assets,
      school: FakeLessonRepository(
        texts: LessonTexts.fromJson({'coach.good': 'Common'}),
      ),
      indexes: {'private': index},
    );
  });

  test('configured chapter ID is the test ID, with real exercises/scripts and no automatic approval', () async {
    final source = content.forId('private.c1')!;
    final trail = await source.trail();
    final lesson = trail.lesson('private.c1')!;
    expect(lesson.exercises.single.id, 'e1');
    expect(lesson.maxScore, 3);
    expect(lesson.lesson.parts.single.script, script);
    expect(lesson.inReview, isTrue);
    expect(trail.lesson('private.c1.test'), isNull);
    expect(
      assets.reads,
      isNot(contains('assets/lessons/endgames/review.json')),
    );
    expect(assets.reads, isNot(contains('assets/lessons/endgames/index.json')));
  });

  test(
    'chapter without optional practice keeps its test and scripted parts',
    () async {
      final raw = jsonDecode(assets.files[chapter]!) as Map<String, dynamic>;
      raw.remove('practice');
      assets.files[chapter] = jsonEncode(raw);
      final lesson = (await content.forId('private.c1')!.trail()).lesson(
        'private.c1',
      )!;
      expect(lesson.practice, isNull);
      expect(lesson.exercises.single.id, 'e1');
      expect(lesson.lesson.parts.single.script, script);
      expect(lesson.maxScore, 3);
    },
  );
  test('texts reuse prefixing and localized/English/common fallback', () async {
    final texts = await content.forId('private.c1')!.texts('pt');
    expect(texts.lessonTitle('private.c1'), 'Título privado');
    expect(texts.step('private.c1', 'intro'), 'Private explanation');
    expect(texts.say('coach.good'), 'Common');
  });

  test('offline unprepared chapter does not hide installed chapter or discard its text', () async {
    final json = jsonDecode(assets.files[index]!) as Map;
    ((json['partes'] as List).first['capitulos'] as List).add({
      'id': 'private.c2',
      'titulo': 'Next chapter',
      'aulas': [
        {'id': 'private.c2', 'tipo': 'teste'},
      ],
    });
    assets.files[index] = jsonEncode(json);
    assets.offline.add('assets/lessons/endgames/private.c2.json');
    final source = content.forId('private.c1')!;
    expect((await source.trail()).lessons.map((l) => l.id), ['private.c1']);
    expect(
      (await source.texts('pt')).lessonTitle('private.c1'),
      'Título privado',
    );
    expect(
      (jsonDecode(assets.files[index]!)['partes'][0]['capitulos'] as List)
          .length,
      2,
    );
  });

  test('successful trail/text reads share the cache and invalidate on source scope change', () async {
    final source = content.forId('private.c1')!;
    final first = await source.trail();
    await source.texts('pt');
    final count = assets.reads.length;
    expect(identical(await source.trail(), first), isTrue);
    await source.texts('pt');
    expect(assets.reads.length, count);
    assets.scope = Object();
    expect(identical(await source.trail(), first), isFalse);
    expect(assets.reads.length, greaterThan(count));
  });

  test(
    'transient unavailability is not cached or replaced by fabricated data',
    () async {
      final source = content.forId('private.c1')!;
      assets.unavailable = chapter;
      await expectLater(
        source.trail(),
        throwsA(isA<LessonContentUnavailable>()),
      );
      assets.unavailable = null;
      expect((await source.trail()).lessons.single.id, 'private.c1');
    },
  );

  test(
    'an account/source switch during loading rejects the old result',
    () async {
      final source = content.forId('private.c1')!;
      assets.gate = Completer<void>();
      final pending = source.trail();
      final rejected = expectLater(
        pending,
        throwsA(isA<LessonContentUnavailable>()),
      );
      assets.scope = Object();
      assets.gate!.complete();
      await rejected;
      assets.gate = null;
      expect((await source.trail()).lessons.single.id, 'private.c1');
    },
  );

  test('only configured namespace/index selects private content', () {
    expect(content.forId('privatex.c1'), isNull);
    expect(content.forId('rook.lucena'), isNull);
    expect(content.forId(null), isNull);
    expect(content.forIndex('assets/lessons/course.json'), isNull);
    expect(
      identical(content.forIndex(index), content.forId('private.c1')),
      isTrue,
    );
    final fromConfig = TrainingEndgameContent.fromConfigs(
      assets,
      school: FakeLessonRepository(),
      configs: [TrainingCourseConfig.pilares],
    );
    expect(
      fromConfig.forIndex(TrainingCourseConfig.pilares.indexSource),
      isNotNull,
    );
    expect(fromConfig.forId('private.c1'), isNull);
  });

  test('confirmed missing optional script is omitted, missing localized text falls back to English', () async {
    assets.files.remove(script);
    assets.files.remove('assets/lessons/pt/endgames/private.c1.json');
    final source = content.forId('private.c1')!;
    expect(
      (await source.trail()).lessons.single.lesson.parts.single.script,
      isNull,
    );
    expect(
      (await source.texts('pt')).lessonTitle('private.c1'),
      'Private title',
    );
  });
}
