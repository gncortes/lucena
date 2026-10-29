import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/training_analytics.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../data/repositories/training/training_repository_test.dart'
    show MemoryPreferences, MemoryContent;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  final config = TrainingCourseConfig.pilares;
  final goal = TrainingGoal(
    kind: GoalKind.exercise,
    ref: 'lesson1',
    itemId: 'e1',
    stars: 1,
    mock: true,
  );
  final exercise = TrainingExercise(
    id: 'e1',
    stars: 1,
    fen: GameRules.initial.fen,
    solution: ['e2e4'],
    mock: true,
  );

  test('exercise cubit logs measured result only once across two instances and reload', () async {
    final now = FakeNow(DateTime(2026, 10, 29, 12));
    final analytics = FakeAnalyticsRepository();
    final coordinator = TrainingAnalytics(now: now, log: analytics.log);
    final resources = TrainingResources(
      banks: {
        'lesson1': [exercise],
      },
    );
    final repository = TrainingRepositoryLocal(
      MemoryPreferences(),
      LessonContentAssets(reader: MemoryContent()),
      installSeed: 'test',
      contentSources: {config.indexSource: () async => resources},
      onSaved: coordinator.onSaved,
    );
    addTearDown(repository.dispose);
    await repository.update(
      config.course,
      (s) => s.copyWith(
        day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
        cycles: {
          'lesson1': ThemeCycle(lessonId: 'lesson1', startedOn: '2026-10-20'),
        },
      ),
    );
    TrainingExerciseCubit build() => TrainingExerciseCubit(
      repository: repository,
      config: config,
      now: now,
      goalKey: goal.key,
      origin: 'home',
      analytics: analytics,
      trainingAnalytics: coordinator,
    );
    final a = build(), b = build();
    addTearDown(a.close);
    addTearDown(b.close);
    await a.load();
    await b.load();
    await a.hint();
    now.advance(const Duration(seconds: 13));
    await a.play('e2e4');
    await b.play('e2e4');
    expect(analytics.eventsNamed('treino_meta_inicio'), hasLength(1));
    expect(analytics.eventsNamed('treino_meta_fim'), hasLength(1));
    final result = analytics.eventsNamed('treino_meta_fim').single.params;
    expect(result['tempo_s'], 13);
    expect(result['origem'], 'home');
    expect(result['mock'], 'sim');
    expect(result['acertou'], 'nao');
    expect(result['dicas'], 1);
    final reopened = build();
    addTearDown(reopened.close);
    await reopened.load();
    expect(analytics.eventsNamed('treino_meta_fim'), hasLength(1));
    expect(analytics.eventsNamed('treino_meta_inicio'), hasLength(1));
  });

  test('opening cubit logs segment counters and durable completion once across instances', () async {
    final now = FakeNow(DateTime(2026, 10, 29, 12));
    final analytics = FakeAnalyticsRepository();
    final coordinator = TrainingAnalytics(now: now, log: analytics.log);
    final trecho = OpeningTrecho(
      id: 't1',
      title: 'Private title never leaves',
      moves: ['e2e4', 'e7e5', 'g1f3'],
      mock: true,
    );
    final resources = TrainingResources(
      openings: {
        'opening1': [trecho],
      },
    );
    final repository = TrainingRepositoryLocal(
      MemoryPreferences(),
      LessonContentAssets(reader: MemoryContent()),
      installSeed: 'test',
      contentSources: {config.indexSource: () async => resources},
      onSaved: coordinator.onSaved,
    );
    addTearDown(repository.dispose);
    await repository.update(
      config.course,
      (s) => s.copyWith(
        day: DayGoals(
          date: '2026-10-29',
          studyDay: true,
          goals: [
            TrainingGoal(
              kind: GoalKind.openings,
              ref: 'openings',
              mock: true,
              items: {'opening1': 't1'},
            ),
          ],
        ),
        openings: {
          'opening1': OpeningTrack(
            lessonId: 'opening1',
            startedOn: '2026-10-20',
          ),
        },
      ),
    );
    TrainingOpeningCubit build() => TrainingOpeningCubit(
      repository: repository,
      config: config,
      now: now,
      origin: 'home',
      analytics: analytics,
      trainingAnalytics: coordinator,
    );
    final a = build(), b = build();
    addTearDown(a.close);
    addTearDown(b.close);
    await a.load(lessonId: 'opening1');
    await b.load(lessonId: 'opening1');
    await a.play('d2d4');
    await a.hint();
    await a.play('e2e4');
    a.review(0);
    a.review(2);
    a.notationTap();
    now.advance(const Duration(seconds: 19));
    await a.play('g1f3');
    await b.play('e2e4');
    await b.play('g1f3');
    final result = analytics.eventsNamed('treino_trecho_fim').single.params;
    expect(result['tempo_s'], 19);
    expect(result['erros'], 1);
    expect(result['toques_voltar'], 1);
    expect(result['toques_avancar'], 1);
    expect(result['toques_notacao'], 1);
    expect(result['mock'], 'sim');
    expect(analytics.eventsNamed('treino_meta_fim'), hasLength(1));
    expect(
      analytics.eventsNamed('treino_meta_fim').single.params['acertou'],
      'nao',
    );
    expect(
      analytics.events.expand((e) => e.params.values),
      isNot(contains(trecho.title)),
    );
  });
}
