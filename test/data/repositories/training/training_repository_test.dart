import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/complete_training_goal.dart';

import '../../../../testing/training/mock_exercise_bank.dart';
import '../../../../testing/training/training_scenario_builder.dart';

class MemoryPreferences extends PreferencesService {
  final values = <String, String>{};
  Completer<void>? gate;
  bool fail = false;
  @override
  Future<String?> getString(String key) async => values[key];
  @override
  Future<void> setString(String key, String value) async {
    await gate?.future;
    if (fail) throw StateError('disk unavailable');
    values[key] = value;
  }
}

class MemoryContent extends LessonContentReader {
  final files = <String, String>{};
  final reads = <String>[];
  @override
  Future<String> read(String path) async {
    reads.add(path);
    return files[path] ?? (throw const LessonContentNotFound());
  }
}

void main() {
  test('cenário tudo feito registra a aula e não a repete amanhã', () {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final done = scenario.allDone();
    expect(done.day!.allDone, isTrue);
    expect(done.completedLessons.containsKey('theme9'), isTrue);
    scenario.now.advance(const Duration(days: 1));
    final tomorrow = BuildDayGoals(scenario.now, scenario.config)(
      done,
      scenario.content,
    );
    expect(tomorrow.day!.goals.first.ref, 'theme10');
  });

  test('cenário dia dois conserva sequência que promove o segundo acerto', () {
    final scenario = TrainingScenarioBuilder(TrainingCourse.pilares);
    final state = scenario.large(cycleDay: 2);
    final goal = state.day!.goals.firstWhere((g) => g.ref == 'theme1');
    final done = CompleteTrainingGoal(scenario.now)
        .exercise(state, scenario.content, goal.key, correct: true);
    expect(done.cycles['theme1']!.level, 2);
    expect(done.cycles['theme1']!.cycleDays, hasLength(2));
  });

  late MemoryPreferences preferences;
  late MemoryContent content;
  late TrainingRepositoryLocal repository;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = MemoryPreferences();
    content = MemoryContent();
    repository = TrainingRepositoryLocal(
      preferences,
      LessonContentAssets(reader: content),
      installSeed: 'fixed',
    );
  });
  tearDown(() async {
    await repository.dispose();
  });

  test(
    'persiste um JSON separado por curso e conserva instalação após reiniciar',
    () async {
      await repository.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(onboardingDone: true),
      );
      await repository.update(
        TrainingCourse.escola,
        (s) => s.copyWith(tourSeen: true),
      );
      expect(preferences.values.keys.toSet(), {
        'training.v1.pilares',
        'training.v1.escola',
      });
      final restarted = TrainingRepositoryLocal(
        preferences,
        LessonContentAssets(reader: content),
        installSeed: 'other',
      );
      addTearDown(restarted.dispose);
      final pilares = await restarted.load(TrainingCourse.pilares);
      expect(pilares.onboardingDone, isTrue);
      expect(pilares.installSeed, 'fixed');
      expect(
        (await restarted.load(TrainingCourse.escola)).onboardingDone,
        isFalse,
      );
    },
  );

  test(
    'gravação é aguardada antes de emitir estado e concluir update',
    () async {
      final received = <TrainingState>[];
      final sub = repository.changes.listen(received.add);
      addTearDown(sub.cancel);
      preferences.gate = Completer<void>();
      var returned = false;
      final updating = repository
          .update(
            TrainingCourse.pilares,
            (s) => s.copyWith(onboardingDone: true),
          )
          .then((_) => returned = true);
      await Future<void>.delayed(Duration.zero);
      expect(returned, isFalse);
      expect(received, isEmpty);
      expect(preferences.values, isEmpty);
      preferences.gate!.complete();
      await updating;
      await Future<void>.delayed(Duration.zero);
      expect(returned, isTrue);
      expect(received.single.onboardingDone, isTrue);
    },
  );

  test(
    'transações concorrentes do mesmo curso não perdem atualizações',
    () async {
      await Future.wait([
        repository.update(
          TrainingCourse.pilares,
          (s) => s.copyWith(
            completedLessons: {...s.completedLessons, 'a': '2026-10-26'},
          ),
        ),
        repository.update(
          TrainingCourse.pilares,
          (s) => s.copyWith(
            completedLessons: {...s.completedLessons, 'b': '2026-10-26'},
          ),
        ),
      ]);
      expect(
        (await repository.load(TrainingCourse.pilares)).completedLessons.keys
            .toSet(),
        {'a', 'b'},
      );
    },
  );

  test(
    'erro de disco não emite estado e não bloqueia próxima transação',
    () async {
      final received = <TrainingState>[];
      final sub = repository.changes.listen(received.add);
      addTearDown(sub.cancel);
      preferences.fail = true;
      await expectLater(
        repository.update(
          TrainingCourse.pilares,
          (s) => s.copyWith(onboardingDone: true),
        ),
        throwsStateError,
      );
      expect(received, isEmpty);
      preferences.fail = false;
      await repository.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(tourSeen: true),
      );
      final state = await repository.load(TrainingCourse.pilares);
      expect(state.onboardingDone, isFalse);
      expect(state.tourSeen, isTrue);
    },
  );

  test(
    'JSON desconhecido ou de outro curso é recusado sem apagar dado',
    () async {
      const raw = '{"version":99}';
      preferences.values['training.v1.pilares'] = raw;
      await expectLater(
        repository.load(TrainingCourse.pilares),
        throwsFormatException,
      );
      await expectLater(
        repository.update(TrainingCourse.pilares, (s) => s),
        throwsFormatException,
      );
      expect(preferences.values['training.v1.pilares'], raw);
      preferences.values['training.v1.pilares'] = jsonEncode(
        TrainingState(course: TrainingCourse.escola, installSeed: 'x').toJson(),
      );
      await expectLater(
        repository.load(TrainingCourse.pilares),
        throwsFormatException,
      );
    },
  );

  test('índice ausente retorna conteúdo vazio e não lê asset do APK', () async {
    expect(
      (await repository.resources(TrainingCourse.pilares)).lessons,
      isEmpty,
    );
    expect(content.reads, ['assets/courses/pilares/index.json']);
  });

  test(
    'índice do exportador lê banco mock e omite arquivo inexistente',
    () async {
      content.files['assets/courses/pilares/index.json'] = jsonEncode({
        'partes': [
          {
            'id': 'p1',
            'titulo': 'Parte 1',
            'capitulos': [
              {
                'id': 'c1',
                'titulo': 'Capítulo 1',
                'aulas': [
                  {
                    'id': 'topic',
                    'tipo': 'tema',
                    'titulo': 'Tema',
                    'resumo': 'Resumo',
                  },
                  {
                    'id': 'missing',
                    'tipo': 'tema',
                    'titulo': 'Ausente',
                    'resumo': '',
                  },
                  {
                    'id': 'opening',
                    'tipo': 'abertura',
                    'titulo': 'Abertura',
                    'resumo': '',
                  },
                ],
              },
            ],
          },
        ],
      });
      content.files['assets/lessons/treino/topic.json'] = jsonEncode({
        'aula': 'topic',
        'versao': 'synthetic',
        'exercicios': MockExerciseBank.forLesson('topic')
            .map((e) => e.toJson())
            .toList(),
      });
      content.files['assets/lessons/treino/aberturas/opening.json'] =
          jsonEncode({
            'aula': 'opening',
            'cor': 'pretas',
            'trechos': [
              {
                'id': 't1',
                'titulo': 'Linha',
                'lances': ['d2d4', 'g8f6'],
                'mock': true,
              },
            ],
          });
      final data = await repository.resources(TrainingCourse.pilares);
      expect(data.lessons.map((l) => l.id), ['topic', 'missing', 'opening']);
      expect(data.banks.keys, ['topic']);
      expect(data.banks['topic'], hasLength(14));
      expect(data.banks['topic']!.every((e) => e.mock), isTrue);
      expect(data.openings['opening']!.single.black, isTrue);
    },
  );

  test(
    'cenário grande de sete temas, reforço e quatro aberturas faz round trip',
    () async {
      final builder = TrainingScenarioBuilder(TrainingCourse.pilares);
      final scenario = builder.large(cycleDay: 4);
      await repository.update(
        TrainingCourse.pilares,
        (s) => TrainingState.fromJson({
          ...scenario.toJson(),
          'installSeed': s.installSeed,
        }),
      );
      final state = await repository.load(TrainingCourse.pilares);
      expect(state.day!.goals, hasLength(10));
      expect(state.day!.goals.last.items, hasLength(4));
      expect(state.cycles, hasLength(8));
      final fake = builder.repository(scenario);
      addTearDown(fake.dispose);
      expect(
        (await fake.load(TrainingCourse.pilares)).toJson(),
        scenario.toJson(),
      );
    },
  );
}
