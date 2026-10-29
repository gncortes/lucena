import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/learning/learning_repository.dart';
import 'package:lucena/data/repositories/training/training_learning_bridge.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/home_course_card.dart';
import 'package:lucena/domain/use_cases/training/training_date.dart';
import 'package:dartchess/dartchess.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/training/e2e_training.dart';
import '../../../testing/training/training_scenario_builder.dart';

/// Representative native index shape, including tests between theme groups.
final class _IndexReader extends LessonContentReader {
  final requests = <String>[];
  @override
  Future<String> read(String path) async {
    requests.add(path);
    return jsonEncode({
      'partes': [
        {
          'id': 'fundamentos',
          'titulo': 'Fundamentos',
          'capitulos': [
            {
              'id': 'conceitos',
              'titulo': 'Conceitos',
              'aulas': [
                for (var i = 1; i <= 12; i++) ...[
                  {
                    'id': 'pilares.conceito_$i',
                    'tipo': 'tema',
                    'titulo': 'Conceito $i',
                  },
                  if (i == 4 || i == 8)
                    {
                      'id': 'pilares.teste_$i',
                      'tipo': 'teste',
                      'titulo': 'Teste $i',
                    },
                ],
                for (var i = 1; i <= 4; i++)
                  {
                    'id': 'pilares.abertura_$i',
                    'tipo': 'abertura',
                    'titulo': 'Abertura $i',
                  },
              ],
            },
          ],
        },
      ],
    });
  }
}

void main() {
  const course = TrainingCourse.pilares;
  late _IndexReader reader;
  late E2ETrainingRepository repository;
  late FakeNow now;
  E2ETrainingRepository reopen() => E2ETrainingRepository(
    PreferencesService(),
    LessonContentAssets(reader: reader),
  );
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    reader = _IndexReader();
    repository = reopen();
    now = FakeNow(DateTime(2026));
  });

  test('historic generic defaults stay usable', () {
    final builder = TrainingScenarioBuilder(course);
    expect(builder.large().cycles.keys, containsAll(['theme1', 'theme8']));
    expect(builder.large().openings.keys, [
      'opening1',
      'opening2',
      'opening3',
      'opening4',
    ]);
    expect(builder.allDone().day!.goals.every((g) => g.done), isTrue);
    expect(builder.doubled().day!.doubled, isTrue);
  });

  for (final entry in e2eGoalsScenarios.entries) {
    test(
      'native goals ${entry.value} keeps real IDs, clock and disk state',
      () async {
        await repository.seed(entry.key, now);
        final state = await repository.load(course);
        expect(state.day!.date, trainingDate(now()));
        final resources = await repository.resources(course);
        final ids = resources.lessons.map((lesson) => lesson.id).toSet();
        for (final goal in state.day!.goals) {
          if (goal.kind != GoalKind.openings) {
            expect(ids, contains(goal.ref));
          }
        }
        final saved = await reopen().load(course);
        expect(saved.toJson(), state.toJson());
      },
    );
  }

  test(
    'Home meta uses a legal black mock and preserves it after restart',
    () async {
      await repository.seed(E2ETrainingScenario.meta, now);
      final state = await repository.load(course);
      final reopened = reopen();
      final resources = await reopened.resources(course);
      final card = homeCourseCard(state, resources)!;
      expect(card.status, HomeCourseStatus.exercise);
      final item = resources.banks[card.ref]!.firstWhere(
        (e) => e.id == card.goal!.itemId,
      );
      expect(item.fen.split(' ')[1], 'b');
      expect(item.mock, true);
      final position = GameRules.fromFen(item.fen)!;
      final played = GameRules.play(
        position,
        Move.parse(item.solution.single)!,
      );
      expect(played, isNotNull);
      expect(played!.position.isCheckmate, true);
      expect((await reopened.load(course)).day!.next!.key, card.goal!.key);
    },
  );

  test(
    'native index IDs, completed earlier tests, mock banks and local restart',
    () async {
      await repository.seed(E2ETrainingScenario.large, now);
      final state = await repository.load(course);
      expect(state.installSeed, e2eTrainingSeed);
      expect(state.cycles.length, 8);
      expect(state.openings.length, 4);
      expect(
        state.completedLessons.keys,
        containsAll(['pilares.teste_4', 'pilares.teste_8']),
      );
      expect(state.day!.goals.first.ref, 'pilares.conceito_9');
      final content = await repository.resources(course);
      expect(
        content.banks.values.expand((b) => b).every((e) => e.mock),
        isTrue,
      );
      expect(
        content.openings.values.expand((b) => b).every((e) => e.mock),
        isTrue,
      );
      expect(content.lessons.every((l) => l.groupId == 'conceitos'), isTrue);
      expect(reader.requests, ['assets/courses/pilares/index.json']);
      expect((await reopen().load(course)).toJson(), state.toJson());
    },
  );

  test('large and cycle visual seeds keep coherent goals', () async {
    for (final scenario in E2ETrainingScenario.values.where(
      (s) => !s.name.startsWith('school') && !e2eGoalsScenarios.containsKey(s),
    )) {
      await repository.seed(scenario, now);
      final state = await repository.load(course);
      expect(state.installSeed, e2eTrainingSeed);
      if (scenario == E2ETrainingScenario.welcome) {
        expect(state.onboardingDone, isFalse);
      } else {
        expect(state.onboardingDone, isTrue);
        if (scenario == E2ETrainingScenario.cycle) {
          expect(state.cycles.length, 1);
          expect(state.day!.goals.length, 1);
          expect(state.day!.goals.single.kind, GoalKind.exercise);
          expect(state.cycles.values.single.days, isEmpty);
        } else {
          expect(state.cycles.length, greaterThanOrEqualTo(8));
        }
      }
      if (scenario == E2ETrainingScenario.done) {
        expect(state.day!.goals.every((g) => g.done), isTrue);
      }
      if (scenario == E2ETrainingScenario.dayOff) {
        expect(state.day!.studyDay, isFalse);
      }
      if (scenario == E2ETrainingScenario.doubled) {
        expect(state.day!.doubled, isTrue);
      }
    }
  });

  test('guest explicit Learning completion updates training durably', () async {
    await repository.seed(E2ETrainingScenario.large, now);
    final learning = LearningRepository(
      PreferencesService(),
      now,
      currentUid: () => null,
      versionOf: (_, _) async => null,
      onUnitCompleted: TrainingLearningBridge(repository).call,
    );
    await learning.notifyUnitCompleted(
      owner: null,
      kind: 'endgame_lesson',
      unitId: 'pilares/conceito_9',
    );
    final state = await reopen().load(course);
    expect(state.completedLessons, contains('pilares.conceito_9'));
    expect(state.day!.goals.first.done, isTrue);
  });
}
