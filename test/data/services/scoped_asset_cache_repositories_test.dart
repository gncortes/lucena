import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/course_preview/course_preview_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/repositories/school/visible_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/visible_endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/wiki/wiki_links_repository_asset.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/explanation.dart';

// P2 scope: decoded caches only, synthetic content, no teaching changes.
// Validation: the principal owns Flutter/Dart and must run this suite/analyze.
const _fen = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
const _lesson = 'synthetic';
const _script = 'assets/lessons/roteiros/synthetic.json';

class _Reader extends LessonContentReader {
  String account = 'A';
  bool unavailable = false;
  int reads = 0;
  final errors = <String, Object>{};
  final overrides = <String, String>{};
  Completer<void>? gate;
  final started = Completer<void>();

  @override
  Object get cacheScope => account;

  @override
  Future<String> read(String path) async {
    reads++;
    final value = overrides[path] ?? _fixtures(account)[path];
    final error = errors[path];
    final failed = unavailable;
    final pending = gate;
    gate = null;
    if (!started.isCompleted) started.complete();
    if (pending != null) await pending.future;
    if (failed) throw const LessonContentUnavailable();
    if (error != null) throw error;
    if (value == null) throw const LessonContentNotFound();
    return value;
  }
}

typedef _Read = Future<String?> Function();
typedef _Case = ({
  String name,
  bool fallback,
  _Read Function(LessonContentAssets assets) create,
});

final List<_Case> _cases = [
  (
    name: 'visible school wrapper',
    fallback: false,
    create: (assets) {
      final repo = VisibleLessonRepository(
        AssetLessonRepository(assets),
        ids: {_lesson},
      );
      return () async => (await repo.course()).modules.single.id;
    },
  ),
  (
    name: 'visible endgames wrapper',
    fallback: false,
    create: (assets) {
      final repo = VisibleEndgameLessonRepository(
        AssetEndgameLessonRepository(
          assets,
          school: AssetLessonRepository(assets),
        ),
        ids: {_lesson},
      );
      return () async => (await repo.trail()).modules.single.id;
    },
  ),
  (
    name: 'school course',
    fallback: false,
    create: (assets) {
      final repo = AssetLessonRepository(assets);
      return () async => (await repo.course()).modules.single.id;
    },
  ),
  (
    name: 'school texts',
    fallback: false,
    create: (assets) {
      final repo = AssetLessonRepository(assets);
      return () async => (await repo.texts('pt')).say('marker');
    },
  ),
  (
    name: 'script',
    fallback: false,
    create: (assets) {
      final repo = AssetLessonScriptRepository(assets);
      return () async => (await repo.script(_script)).partId;
    },
  ),
  (
    name: 'script texts',
    fallback: false,
    create: (assets) {
      final repo = AssetLessonScriptRepository(assets);
      return () async => (await repo.texts(_lesson, 'pt')).say('marker');
    },
  ),
  (
    name: 'endgame trail',
    fallback: false,
    create: (assets) {
      final repo = AssetEndgameLessonRepository(
        assets,
        school: AssetLessonRepository(assets),
      );
      return () async => (await repo.trail()).modules.single.id;
    },
  ),
  (
    name: 'endgame texts',
    fallback: false,
    create: (assets) {
      final repo = AssetEndgameLessonRepository(
        assets,
        school: AssetLessonRepository(assets),
      );
      return () async => (await repo.texts('pt')).say('synthetic.title');
    },
  ),
  (
    name: 'feedback rows',
    fallback: true,
    create: (assets) {
      final repo = AssetExerciseFeedbackRepository(assets);
      return () => repo.find(
        lessonId: _lesson,
        exerciseId: 'e1',
        kind: 'exercise',
        turn: 1,
        fen: _fen,
        uci: 'd2d3',
        language: 'pt',
      );
    },
  ),
  (
    name: 'feedback positions',
    fallback: true,
    create: (assets) {
      final repo = AssetExerciseFeedbackRepository(assets);
      return () async => (await repo.findPayload(
        lessonId: _lesson,
        exerciseId: 'e1',
        kind: 'exercise',
        turn: 1,
        fen: _fen,
        language: 'pt',
        state: ExplanationState.intro,
      ))?.explanations.single.texts.single;
    },
  ),
  (
    name: 'feedback review',
    fallback: true,
    create: (assets) {
      final repo = AssetExerciseFeedbackRepository(assets);
      return () async => (await repo.findExerciseReview(
        lessonId: _lesson,
        exerciseId: 'e1',
        language: 'pt',
      ))?.explanations.single.texts.single;
    },
  ),
  (
    name: 'preview',
    fallback: true,
    create: (assets) {
      final repo = AssetCoursePreviewRepository(assets);
      return () async => (await repo.load())?.sale.title;
    },
  ),
  (
    name: 'wiki links',
    fallback: true,
    create: (assets) {
      final repo = AssetWikiLinksRepository(assets);
      return () async => (await repo.links()).url('marker', 'pt')?.fragment;
    },
  ),
];

Future<void> _expectUnavailable(_Case scenario, _Read read) async {
  if (scenario.fallback) {
    expect(await read(), isNull);
  } else {
    await expectLater(read(), throwsA(isA<LessonContentUnavailable>()));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in _cases) {
    test('${scenario.name}: failure then recovery on same instance', () async {
      final reader = _Reader()..unavailable = true;
      final read = scenario.create(LessonContentAssets(reader: reader));
      await _expectUnavailable(scenario, read);
      reader.unavailable = false;
      expect(await read(), 'A');
      final reads = reader.reads;
      expect(await read(), 'A');
      expect(reader.reads, reads);
    });

    test('${scenario.name}: account A never survives account B', () async {
      final reader = _Reader();
      final read = scenario.create(LessonContentAssets(reader: reader));
      expect(await read(), 'A');
      reader.account = 'B';
      reader.unavailable = true;
      await _expectUnavailable(scenario, read);
      reader.unavailable = false;
      expect(await read(), 'B');
    });

    test('${scenario.name}: rejects account switch during read', () async {
      final gate = Completer<void>();
      final reader = _Reader()..gate = gate;
      final read = scenario.create(LessonContentAssets(reader: reader));
      final pending = _expectUnavailable(scenario, read);
      await reader.started.future;
      reader.account = 'B';
      gate.complete();
      await pending;
      expect(await read(), 'B');
    });

    test(
      '${scenario.name}: late A result preserves concurrent B cache',
      () async {
        final gate = Completer<void>();
        final reader = _Reader()..gate = gate;
        final read = scenario.create(LessonContentAssets(reader: reader));
        final pending = _expectUnavailable(scenario, read);
        await reader.started.future;
        reader.account = 'B';
        expect(await read(), 'B');
        gate.complete();
        await pending;
        final reads = reader.reads;
        expect(await read(), 'B');
        expect(reader.reads, reads);
      },
    );
  }

  for (final path in [
    AssetLessonScriptRepository.genericPath('en'),
    AssetEndgameLessonRepository.lessonPath(_lesson),
  ]) {
    test('optional script read propagates transport failure: $path', () async {
      final reader = _Reader();
      reader.errors[path] = const LessonContentUnavailable();
      final repo = AssetLessonScriptRepository(
        LessonContentAssets(reader: reader),
      );
      await expectLater(
        repo.texts(_lesson, 'pt'),
        throwsA(isA<LessonContentUnavailable>()),
      );
      reader.errors.clear();
      expect((await repo.texts(_lesson, 'pt')).say('marker'), 'A');
    });

    for (final error in [
      const LessonContentNotFound(),
      const FormatException('optional malformed fixture'),
    ]) {
      test('optional script read preserves missing/parse handling: $path '
          '${error.runtimeType}', () async {
        final reader = _Reader();
        reader.errors[path] = error;
        final repo = AssetLessonScriptRepository(
          LessonContentAssets(reader: reader),
        );
        expect((await repo.texts(_lesson, 'pt')).say('marker'), 'A');
      });
    }
  }

  test('endgame texts retry after strict trail failure', () async {
    final reader = _Reader();
    reader.errors[AssetEndgameLessonRepository.indexPath] =
        const LessonContentUnavailable();
    final assets = LessonContentAssets(reader: reader);
    final repo = AssetEndgameLessonRepository(
      assets,
      school: AssetLessonRepository(assets),
    );
    await expectLater(
      repo.texts('pt'),
      throwsA(isA<LessonContentUnavailable>()),
    );
    reader.errors.clear();
    expect((await repo.texts('pt')).say('synthetic.title'), 'A');
  });

  test(
    'feedback positions do not survive missing positions in new account',
    () async {
      final reader = _Reader();
      final repo = AssetExerciseFeedbackRepository(
        LessonContentAssets(reader: reader),
      );
      Future<ExplanationPayload?> payload() => repo.findExerciseReview(
        lessonId: _lesson,
        exerciseId: 'e1',
        language: 'pt',
      );
      expect((await payload())?.explanations.single.texts.single, 'A');
      reader.account = 'B';
      reader.overrides[AssetExerciseFeedbackRepository.assetPath(_lesson)] =
          jsonEncode({'lesson': _lesson, 'rows': []});
      expect(await payload(), isNull);
    },
  );
}

Map<String, String> _fixtures(String marker) {
  final position = {'kind': 'exercise', 'id': 'e1', 'turn': 1, 'fen': _fen};
  return {
    AssetLessonRepository.coursePath: jsonEncode({
      'modules': [
        {
          'id': marker,
          'lessons': [
            {'id': _lesson, 'steps': [], 'roteiro': _script},
          ],
        },
      ],
    }),
    for (final language in ['en', 'pt']) ...{
      AssetLessonRepository.textsPath(language): jsonEncode({'marker': marker}),
      AssetLessonScriptRepository.genericPath(language): '{}',
      AssetLessonScriptRepository.lessonTextsPath(_lesson, language):
          jsonEncode({'marker': marker, 'title': marker}),
    },
    _script: jsonEncode({'licao': _lesson, 'parte': marker, 'etapas': []}),
    AssetEndgameLessonRepository.indexPath: jsonEncode({
      'modules': [
        {
          'id': marker,
          'lessons': [_lesson],
        },
      ],
    }),
    AssetEndgameLessonRepository.reviewPath: '{"lessons":[],"failed":[]}',
    AssetEndgameLessonRepository.lessonPath(_lesson): jsonEncode({
      'id': _lesson,
      'module': marker,
      'parts': [
        {'id': 'part', 'steps': [], 'roteiro': _script},
      ],
      'steps': [],
      'exercises': [],
      'passScore': 0,
      'practice': {'fen': _fen},
    }),
    AssetExerciseFeedbackRepository.assetPath(_lesson): jsonEncode({
      'lesson': _lesson,
      'rows': [
        {...position, 'uci': 'd2d3', 'en': marker, 'pt': marker},
      ],
      'positions': [
        {
          ...position,
          'explanations': {
            'pt': {
              'positionId': 'synthetic:e1',
              'explanations': [
                {
                  'id': 'context',
                  'kind': 'context',
                  'texts': [marker],
                },
              ],
            },
          },
        },
      ],
    }),
    AssetWikiLinksRepository.path: jsonEncode({
      'marker': {'pt': 'https://example.com/#$marker'},
    }),
    AssetCoursePreviewRepository.path: jsonEncode({
      'sale': {
        for (final key in [
          'overline',
          'title',
          'line',
          'exercises',
          'price',
          'priceNote',
          'speech',
          'summaryNote',
        ])
          key: marker,
        'lessons': 0,
        for (final key in [
          'how',
          'learn',
          'audienceItems',
          'included',
          'app',
          'parts',
          'faq',
        ])
          key: [],
        'audience': {'title': marker},
        'level': {'title': marker, 'examples': []},
        'band': {
          for (final key in [
            'heading',
            'line',
            'chartTitle',
            'chartNote',
            'source',
          ])
            key: marker,
          'ranges': [],
          'themes': [],
          'warning': {'title': marker},
        },
      },
      'map': {
        'continue': {
          'part': marker,
          'number': 0,
          'title': marker,
          'summary': marker,
        },
        'test': marker,
        'part': {'label': marker, 'title': marker, 'done': 0, 'total': 0},
        'chapters': [],
      },
      'chapter': {
        'part': marker,
        'number': 0,
        'count': 0,
        'title': marker,
        'lessons': [],
        'exercises': {'number': marker, 'count': 0},
        'start': marker,
      },
    }),
  };
}
