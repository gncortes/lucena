import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/learning/learning_repository.dart';
import 'package:lucena/data/repositories/training/training_history_source.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/learning_record.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/training/school_training_progress.dart';
import 'package:lucena/domain/models/training/training_analytics_state.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/day_goals.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_course_training_repository.dart';
import '../../../../testing/fakes/fake_now.dart';

void main() {
  const config = TrainingCourseConfig.pilares;
  const theme = TrainingLesson(
    id: 'pilares.c1.topic',
    kind: TrainingLessonKind.theme,
    title: 'Tema',
  );
  const exam = TrainingLesson(
    id: 'pilares.c1',
    kind: TrainingLessonKind.test,
    title: 'Teste',
  );
  const opening = TrainingLesson(
    id: 'pilares.ab1.london',
    kind: TrainingLessonKind.opening,
    title: 'Abertura',
  );
  final now = FakeNow(DateTime(2026, 10, 26, 12));
  late FakeTrainingRepository training;
  late LearningRepository learning;
  late String? uid;
  late String? version;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    uid = 'owner';
    version = 'current';
    training = FakeTrainingRepository(
      content: {
        config.course: TrainingResources(lessons: [theme, exam, opening]),
      },
    );
    learning = LearningRepository(
      PreferencesService(),
      now,
      currentUid: () => uid,
      versionOf: (_, _) async => version,
    );
  });
  tearDown(() => training.dispose());
  Future<void> bootstrap() => TrainingHistorySource(
    training,
    learning: learning,
    now: now,
  ).bootstrap(config);
  LearningRecord record({
    String kind = 'endgame_lesson',
    String id = 'pilares.c1/topic',
    String revision = 'current',
    bool completed = true,
    bool passed = false,
    DateTime? at,
  }) => LearningRecord(
    kind: kind,
    unitId: id,
    version: revision,
    contentCompletedAt: completed
        ? at ?? now().subtract(const Duration(days: 2))
        : null,
    testPassedAt: passed ? at ?? now().subtract(const Duration(days: 2)) : null,
  );
  test(
    'current observed history seeds the original date and follow-up once',
    () async {
      await learning.restore(uid!, [record()]);
      await bootstrap();
      final state = await training.load(config.course);
      expect(state.completedLessons[theme.id], '2026-10-24');
      expect(state.cycles[theme.id]!.startedOn, '2026-10-24');
      expect(state.onboardingDone, isFalse);
      await bootstrap();
      expect(training.writes, 1);
      expect((await learning.load(uid!)).length, 1);
    },
  );
  test(
    'provisional import is removed when content changes before onboarding',
    () async {
      await learning.restore(uid!, [record()]);
      await bootstrap();
      expect(
        (await training.load(config.course)).completedLessons[theme.id],
        '2026-10-24',
      );
      version = 'next';
      await bootstrap();
      final state = await training.load(config.course);
      expect(state.completedLessons, isEmpty);
      expect(state.cycles, isEmpty);
      expect((await learning.load(uid!)).single.version, 'current');
    },
  );
  test('restart preserves provisional provenance and a current replacement is imported once', () async {
    await learning.restore(uid!, [record()]);
    await bootstrap();
    final previous = training;
    training = FakeTrainingRepository(
      states: {config.course: await previous.load(config.course)},
      content: previous.content,
    );
    await previous.dispose();
    version = 'next';
    await bootstrap();
    expect((await training.load(config.course)).completedLessons, isEmpty);
    await learning.restore(uid!, [
      record(revision: 'next', at: DateTime(2026, 10, 25)),
    ]);
    await bootstrap();
    final restored = await training.load(config.course);
    expect(restored.completedLessons[theme.id], '2026-10-25');
    expect(restored.cycles[theme.id]!.startedOn, '2026-10-25');
    final writes = training.writes;
    await bootstrap();
    expect(training.writes, writes);
    expect(await learning.load(uid!), hasLength(2));
  });
  test(
    'account change or guest clears only provisional account history',
    () async {
      await training.update(
        config.course,
        (s) => s.copyWith(completedLessons: {'operational': '2026-10-20'}),
      );
      await learning.restore(uid!, [record()]);
      await bootstrap();
      uid = 'other';
      await bootstrap();
      expect((await training.load(config.course)).completedLessons, {
        'operational': '2026-10-20',
      });
      expect((await learning.load('owner')), hasLength(1));
      await learning.restore(uid!, [record()]);
      await bootstrap();
      uid = null;
      await bootstrap();
      expect((await training.load(config.course)).completedLessons, {
        'operational': '2026-10-20',
      });
    },
  );
  test('failed cleanup write keeps data and emits nothing; retry is durable and replay is silent', () async {
    await learning.restore(uid!, [record()]);
    await bootstrap();
    final original = training.saved[config.course];
    final changes = <TrainingState>[];
    final subscription = training.changes.listen(changes.add);
    addTearDown(subscription.cancel);
    version = 'next';
    training.writeError = StateError('disk unavailable');
    await expectLater(bootstrap(), throwsStateError);
    expect(training.saved[config.course], original);
    expect(changes, isEmpty);
    training.writeError = null;
    await bootstrap();
    await Future<void>.delayed(Duration.zero);
    expect((await training.load(config.course)).completedLessons, isEmpty);
    expect(changes, hasLength(1));
    final writes = training.writes;
    await bootstrap();
    await Future<void>.delayed(Duration.zero);
    expect(training.writes, writes);
    expect(changes, hasLength(1));
  });
  test(
    'existing unmarked progress and changed imported cycles remain operational',
    () async {
      await training.update(
        config.course,
        (s) => s.copyWith(
          completedLessons: {exam.id: '2026-10-20'},
          cycles: {
            'existing': ThemeCycle(
              lessonId: 'existing',
              startedOn: '2026-10-20',
              level: 3,
            ),
          },
        ),
      );
      await learning.restore(uid!, [record()]);
      await bootstrap();
      await training.update(
        config.course,
        (s) => s.copyWith(
          cycles: {
            ...s.cycles,
            theme.id: s.cycles[theme.id]!.copyWith(
              level: 2,
              days: [
                const ThemeDay(
                  date: '2026-10-25',
                  exerciseId: 'played',
                  stars: 1,
                  correct: true,
                ),
              ],
            ),
          },
        ),
      );
      version = 'next';
      await bootstrap();
      final state = await training.load(config.course);
      expect(state.completedLessons[exam.id], '2026-10-20');
      expect(state.completedLessons[theme.id], '2026-10-24');
      expect(state.cycles[theme.id]!.level, 2);
      expect(state.cycles['existing']!.level, 3);
      final writes = training.writes;
      await bootstrap();
      expect(training.writes, writes);
    },
  );
  test('preexisting track and unrelated school/analytics survive provisional cleanup', () async {
    final existing = ThemeCycle(
      lessonId: theme.id,
      startedOn: '2026-10-20',
      level: 2,
    );
    await training.update(
      config.course,
      (s) => s.copyWith(
        cycles: {theme.id: existing},
        school: SchoolTrainingProgress(pieceLevels: {'rook': 2}),
        analytics: TrainingAnalyticsState(
          date: '2026-10-26',
          attempts: {
            'unrelated': TrainingAnalyticsAttempt(
              started: now(),
              origin: 'home',
              points: 22,
            ),
          },
        ),
      ),
    );
    await learning.restore(uid!, [record()]);
    await bootstrap();
    final imported = await training.load(config.course);
    expect(imported.bootstrapImports[theme.id]!.cycleJson, isNull);
    version = 'next';
    await bootstrap();
    final state = await training.load(config.course);
    expect(state.completedLessons, isEmpty);
    expect(state.cycles[theme.id]!.toJson(), existing.toJson());
    expect(state.school.pieceLevels['rook'], 2);
    expect(state.analytics.attempts['unrelated']!.points, 22);
    expect(state.analytics.attempts['unrelated']!.origin, 'home');
  });
  test(
    'an untouched imported opening is removed but a played opening remains',
    () async {
      await learning.restore(uid!, [record(id: 'pilares.ab1/london')]);
      await bootstrap();
      version = 'next';
      await bootstrap();
      expect((await training.load(config.course)).openings, isEmpty);
      version = 'current';
      await bootstrap();
      await training.update(
        config.course,
        (s) => s.copyWith(
          openings: {
            opening.id: s.openings[opening.id]!.withMistake('segment', 0),
          },
        ),
      );
      version = 'next';
      await bootstrap();
      final state = await training.load(config.course);
      expect(state.completedLessons[opening.id], '2026-10-24');
      expect(state.openings[opening.id]!.pendingMistakes['segment'], [0]);
    },
  );
  test(
    'a frozen day is not rewritten even when onboarding flag is absent',
    () async {
      await learning.restore(uid!, [record()]);
      await bootstrap();
      await training.update(
        config.course,
        (s) => s.copyWith(
          day: DayGoals(
            date: '2026-10-26',
            studyDay: true,
            goals: [
              TrainingGoal(
                kind: GoalKind.exercise,
                ref: theme.id,
                itemId: 'frozen',
              ),
            ],
          ),
        ),
      );
      final original = training.saved[config.course];
      final writes = training.writes;
      version = 'next';
      await bootstrap();
      expect(training.saved[config.course], original);
      expect(training.writes, writes);
    },
  );
  test('bootstrap metadata is immutable, roundtrips and defaults safely for legacy state', () async {
    await learning.restore(uid!, [record()]);
    await bootstrap();
    final state = await training.load(config.course);
    expect(state.bootstrapImports[theme.id]!.version, 'current');
    expect(() => state.bootstrapImports.clear(), throwsUnsupportedError);
    final json = jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
    expect(
      TrainingState.fromJson(json).bootstrapImports[theme.id]!.cycleJson,
      isNotNull,
    );
    json.remove('bootstrapImports');
    final legacy = TrainingState.fromJson(json);
    expect(legacy.bootstrapImports, isEmpty);
    await training.update(config.course, (_) => legacy);
    version = 'next';
    await bootstrap();
    expect(
      (await training.load(config.course)).completedLessons[theme.id],
      '2026-10-24',
    );
  });
  test('chapter content alone does not import test approval', () async {
    await learning.restore(uid!, [
      record(kind: 'endgame_chapter', id: exam.id),
    ]);
    await bootstrap();
    expect((await training.load(config.course)).completedLessons, isEmpty);
    await learning.restore(uid!, [
      record(kind: 'endgame_chapter', id: exam.id, passed: true),
    ]);
    await bootstrap();
    expect(
      (await training.load(config.course)).completedLessons
          .containsKey(exam.id),
      isTrue,
    );
  });
  test(
    'obsolete, undated, future and foreign school records are ignored',
    () async {
      for (final item in [
        record(revision: 'old'),
        record(completed: false),
        record(at: now().add(const Duration(days: 1))),
        record(kind: 'school_lesson', id: theme.id),
      ]) {
        await learning.restore(uid!, [item]);
      }
      await bootstrap();
      expect(training.writes, 0);
    },
  );
  test(
    'guest and an already started plan never import account history',
    () async {
      await learning.restore(uid!, [record()]);
      uid = null;
      await bootstrap();
      expect(training.writes, 0);
      uid = 'owner';
      await training.update(
        config.course,
        (s) => s.copyWith(onboardingDone: true),
      );
      await bootstrap();
      expect((await training.load(config.course)).completedLessons, isEmpty);
    },
  );
  test(
    'account switch while fingerprint loads cancels the bootstrap',
    () async {
      await learning.restore(uid!, [record()]);
      final switching = LearningRepository(
        PreferencesService(),
        now,
        currentUid: () => uid,
        versionOf: (_, _) async {
          uid = 'other';
          return version;
        },
      );
      await TrainingHistorySource(
        training,
        learning: switching,
        now: now,
      ).bootstrap(config);
      expect(training.writes, 0);
    },
  );
}
