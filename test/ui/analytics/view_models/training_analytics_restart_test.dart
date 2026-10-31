import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/training_analytics.dart';
import 'package:lucena/ui/training_exercise/view_models/training_exercise_cubit.dart';
import 'package:lucena/ui/training_opening/view_models/training_opening_cubit.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../data/repositories/training/training_repository_test.dart'
    show MemoryPreferences, MemoryContent;

void main() {
  const config = TrainingCourseConfig.pilares;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test(
    'kill keeps home origin, original start and hint with hanging transport',
    () async {
      final now = FakeNow(DateTime(2026, 10, 29, 12));
      final prefs = MemoryPreferences();
      final events = FakeAnalyticsRepository();
      late TrainingRepositoryLocal repository;
      late TrainingAnalytics analytics;
      final goal = TrainingGoal(
        kind: GoalKind.exercise,
        ref: 'theme1',
        itemId: 'exercise1',
        stars: 1,
        mock: true,
      );
      final resources = TrainingResources(
        banks: {
          'theme1': [
            TrainingExercise(
              id: 'exercise1',
              stars: 1,
              fen: GameRules.initial.fen,
              solution: ['e2e4'],
              mock: true,
            ),
          ],
        },
      );
      repository = TrainingRepositoryLocal(
        prefs,
        LessonContentAssets(reader: MemoryContent()),
        installSeed: 'test',
        contentSources: {config.indexSource: () async => resources},
        onSaved: (b, a) => analytics.onSaved(b, a),
      );
      analytics = TrainingAnalytics(
        now: now,
        read: repository.load,
        write: repository.update,
        log: (_) => Completer<void>().future,
      );
      addTearDown(repository.dispose);
      await repository.update(
        config.course,
        (s) => s.copyWith(
          day: DayGoals(date: '2026-10-29', studyDay: true, goals: [goal]),
          cycles: {
            'theme1': ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-20'),
          },
        ),
      );
      var cubit = TrainingExerciseCubit(
        repository: repository,
        config: config,
        now: now,
        goalKey: goal.key,
        origin: 'home',
        trainingAnalytics: analytics,
      );
      await cubit.load().timeout(const Duration(seconds: 1));
      await cubit.hint();
      await cubit.close();
      final stored = TrainingState.fromJson(
        jsonDecode(prefs.values[TrainingRepositoryLocal.key(config.course)]!)
            as Map<String, dynamic>,
      );
      expect(stored.analytics.attempts[goal.key]!.origin, 'home');
      now.advance(const Duration(seconds: 37));
      analytics = TrainingAnalytics(
        now: now,
        read: repository.load,
        write: repository.update,
        log: events.log,
      );
      cubit = TrainingExerciseCubit(
        repository: repository,
        config: config,
        now: now,
        goalKey: goal.key,
        origin: 'metas',
        trainingAnalytics: analytics,
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.elapsed.inSeconds, 37);
      await cubit.play('e2e4');
      expect(events.eventsNamed('treino_meta_inicio'), isEmpty);
      final result = events.eventsNamed('treino_meta_fim').single.params;
      expect(result['origem'], 'home');
      expect(result['tempo_s'], 37);
      expect(result['dicas'], 1);
      expect(result['acertou'], 'nao');
      expect(result['mock'], 'sim');
    },
  );

  test('kill restores segment counters and completion stays atomic on disk failure', () async {
    final now = FakeNow(DateTime(2026, 10, 29, 12));
    final prefs = MemoryPreferences();
    final events = FakeAnalyticsRepository();
    late TrainingAnalytics analytics;
    late TrainingRepositoryLocal repository;
    final trecho = OpeningTrecho(
      id: 'segment1',
      title: 'Private title',
      moves: ['e2e4', 'e7e5', 'g1f3'],
      mock: true,
    );
    final resources = TrainingResources(
      openings: {
        'opening1': [trecho],
      },
    );
    repository = TrainingRepositoryLocal(
      prefs,
      LessonContentAssets(reader: MemoryContent()),
      installSeed: 'test',
      contentSources: {config.indexSource: () async => resources},
      onSaved: (b, a) => analytics.onSaved(b, a),
    );
    TrainingAnalytics coordinator() => TrainingAnalytics(
      now: now,
      read: repository.load,
      write: repository.update,
      log: events.log,
    );
    analytics = coordinator();
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
              items: {'opening1': 'segment1'},
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
    TrainingOpeningCubit build(String origin) => TrainingOpeningCubit(
      repository: repository,
      config: config,
      now: now,
      origin: origin,
      analytics: events,
      trainingAnalytics: analytics,
    );
    var cubit = build('home');
    await cubit.load(lessonId: 'opening1');
    await cubit.play('d2d4');
    await cubit.hint();
    await cubit.play('e2e4');
    cubit.review(0);
    cubit.review(2);
    cubit.notationTap(0);
    await analytics.flush(config.course);
    await cubit.close();
    now.advance(const Duration(seconds: 41));
    analytics = coordinator();
    cubit = build('metas');
    addTearDown(cubit.close);
    await cubit.load(lessonId: 'opening1');
    await cubit.play('e2e4');
    prefs.fail = true;
    await cubit.play('g1f3');
    expect(events.eventsNamed('treino_trecho_fim'), isEmpty);
    prefs.fail = false;
    // Retrying metadata persistence must never emit an unfinished gameplay result.
    await analytics.flush(config.course);
    expect(events.eventsNamed('treino_trecho_fim'), isEmpty);
    await cubit.retry();
    final result = events.eventsNamed('treino_trecho_fim').single.params;
    expect(result['erros'], 1);
    expect(result['toques_voltar'], 1);
    expect(result['toques_avancar'], 1);
    expect(result['toques_notacao'], 1);
    expect(result['tempo_s'], 41);
    expect(events.eventsNamed('treino_trecho_inicio'), hasLength(1));
    expect(events.eventsNamed('treino_meta_inicio'), hasLength(1));
    final meta = events.eventsNamed('treino_meta_fim').single.params;
    expect(meta['origem'], 'home');
    expect(meta['dicas'], 1);
    expect(meta['tempo_s'], 41);
  });
}
