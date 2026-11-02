@Tags(['private-content'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/campaign/linked_lesson_catalog.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/training/training_endgame_content.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_filter.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgame_lesson_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercises_done_screen.dart';
import 'package:lucena/ui/lesson_finished/view_models/lesson_finished_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_race_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/test_app.dart';

/// The index is narrowed to two chapters; chapter/text/script bytes are actual
/// local private inputs, never synthetic practice data or modified assets.
class _PrivateFiles extends AssetService {
  @override
  Future<String> loadString(String path) async {
    if (path == 'assets/courses/pilares/index.json') {
      final original =
          jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
      return jsonEncode({
        ...original,
        'partes': [
          for (final part in original['partes'] as List)
            {
              ...part as Map,
              'capitulos': [
                for (final chapter in part['capitulos'] as List)
                  if (const [
                    'pilares.c1',
                    'pilares.ab1',
                  ].contains((chapter as Map)['id']))
                    chapter,
              ],
            },
        ],
      });
    }
    final file = File(path);
    if (!await file.exists()) throw const LessonContentNotFound();
    return file.readAsString();
  }
}

Map<String, dynamic> _json(String id) =>
    jsonDecode(File('assets/lessons/endgames/$id.json').readAsStringSync())
        as Map<String, dynamic>;
EndgameLesson _lesson(String id) =>
    AssetEndgameLessonRepository.parseLesson(_json(id), inReview: true);
EndgameTrail _trail(EndgameLesson lesson) => EndgameTrail(
  modules: [
    EndgameModule(id: lesson.module, lessons: [lesson]),
  ],
);
FakeEndgameLessonRepository _repo(EndgameLesson lesson) =>
    FakeEndgameLessonRepository(
      trail: _trail(lesson),
      texts: LessonTexts.fromJson({'${lesson.id}.title': 'Private chapter'}),
    );

void main() {
  for (final id in ['pilares.c1', 'pilares.ab1']) {
    test(
      'actual file schema $id preserves chapters, exercises and texts without practice',
      () async {
        final raw = _json(id);
        expect(raw.containsKey('practice'), isFalse);
        final content = TrainingEndgameContent(
          _PrivateFiles(),
          school: FakeLessonRepository(),
          indexes: {'pilares': 'assets/courses/pilares/index.json'},
        );
        final source = content.forId(id)!;
        final lesson = (await source.trail()).lesson(id)!;
        expect(lesson.practice, isNull);
        expect(
          lesson.lesson.parts.map((p) => p.id),
          (raw['parts'] as List).map((p) => (p as Map)['id']),
        );
        expect(lesson.exercises.length, (raw['exercises'] as List).length);
        expect(
          lesson.maxScore,
          (raw['exercises'] as List).fold<int>(
            0,
            (sum, e) => sum + ((e as Map)['stars'] as int),
          ),
        );
        expect(lesson.passScore, raw['passScore']);
        expect(
          lesson.keyPositions.length,
          (raw['keyPositions'] as List).length,
        );
        expect(lesson.references.length, (raw['references'] as List).length);
        final texts = await source.texts('pt');
        final originalTexts = jsonDecode(
          File('assets/lessons/pt/endgames/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final expectedTexts = LessonTexts.fromJson(
          AssetEndgameLessonRepository.prefixed(id, originalTexts),
        ).toJson();
        for (final entry in expectedTexts.entries) {
          expect(texts.toJson()[entry.key], entry.value, reason: entry.key);
        }
        // Missing chapter title comes from real configured index metadata.
        expect(originalTexts.containsKey('title'), isFalse);
        final realIndex = jsonDecode(
          File('assets/courses/pilares/index.json').readAsStringSync(),
        ) as Map;
        final realTitle = [
          for (final part in realIndex['partes'] as List)
            for (final chapter in (part as Map)['capitulos'] as List)
              if ((chapter as Map)['id'] == id) chapter['titulo'],
        ].single;
        expect(texts.lessonTitle(id), realTitle);
        expect(EndgameLessonRules.canPractice(lesson), isFalse);
        expect(EndgameLessonRules.speedrunOf(lesson, []), isNull);
        expect(EndgameLessonFilter.kinds(lesson), isEmpty);
        // Short evidence only, never dump private chapter or FEN contents.
        debugPrint(
          '$id: ${lesson.lesson.parts.length} parts, ${lesson.exercises.length} exercises, ${lesson.maxScore} maximum points, no practice',
        );
      },
    );
  }

  test('public legacy practice remains supported', () {
    final legacy = FakeEndgameLessonRepository.sample.lessons.first;
    expect(legacy.practice, isNotNull);
    expect(EndgameLessonRules.canPractice(legacy), isTrue);
    expect(EndgameLessonFilter.kinds(legacy), isNotEmpty);
  });

  test('campaign and lesson-finished do not invent practice/FEN/race for an absent position', () async {
    final real = _lesson('pilares.c1');
    final noPosition = EndgameLesson(
      id: real.id,
      module: real.module,
      lesson: real.lesson,
      exercises: real.exercises,
      passScore: real.passScore,
      keyPositions: const [],
    );
    final repo = _repo(noPosition);
    final catalog = LinkedLessonCatalog(
      endgames: repo,
      school: FakeLessonRepository(),
    );
    final info = await catalog.info(
      LinkedLesson(LinkedLessonKind.endgame, real.id),
      'pt',
    );
    expect(info, isNotNull);
    expect(info!.fen, isNull);
    final cubit = LessonFinishedCubit(
      kind: SurveyKind.endgames,
      nextId: null,
      lessonId: real.id,
      endgames: repo,
      school: FakeLessonRepository(),
      race: FakeRaceRepository(now: FakeNow(DateTime(2026, 10, 29))),
    );
    addTearDown(cubit.close);
    await cubit.load('pt');
    expect(cubit.state.ready, isTrue);
    expect(cubit.state.hasExercises, isTrue);
    expect(cubit.state.practice, isNull);
    expect(cubit.state.raceSubcategory, isNull);
  });

  for (final result in [false, true]) {
    testWidgets(
      'actual completed chapter has no practice CTA: result=$result',
      (tester) async {
        tester.view
          ..physicalSize = const Size(412, 915)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final lesson = _lesson('pilares.c1');
        final cubit = EndgameLessonCubit(
          lessons: _repo(lesson),
          progress: FakeEndgameProgressRepository(
            EndgameProgress(
              lessons: {
                lesson.id: EndgameLessonProgress(
                  lessonDone: true,
                  approved: true,
                  stars: {for (final e in lesson.exercises) e.id: e.stars},
                ),
              },
            ),
          ),
          journey: FakeJourneyRepository(),
          characters: FakeCharacterRepository(),
        );
        addTearDown(cubit.close);
        await cubit.load(lesson.id, 'pt');
        expect(cubit.state.ready, isTrue);
        await tester.pumpWidget(
          TestApp(
            child: BlocProvider.value(
              value: cubit,
              child: result
                  ? const ExercisesDoneScreen()
                  : const EndgameLessonScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(ExercisesDoneKeys.practice), findsNothing);
        if (!result) {
          expect(find.byKey(EndgameLessonKeys.continueButton), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
