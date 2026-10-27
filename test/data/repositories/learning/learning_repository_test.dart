import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/domain/models/campaign.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/data/repositories/learning/learning_repository.dart';
import 'package:lucena/data/repositories/learning/learning_lesson_source.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/learning_record.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/progress_summary.dart';
import 'package:lucena/domain/use_cases/progress_merge.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';

void main() {
  late LearningRepository learning;
  late FakeNow now;
  String? uid;
  String revision = 'v1';
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = FakeNow(DateTime.utc(2026, 10, 27));
    uid = 'a';
    revision = 'v1';
    learning = LearningRepository(
      PreferencesService(),
      now,
      currentUid: () => uid,
      versionOf: (_, _) async => revision,
    );
  });
  const checkpoint = LessonCheckpoint(lessonId: 'mates.queen', step: 0);
  LearningLessonSource school(
    FakeSchoolProgressRepository progress,
    FakeAnalyticsRepository analytics,
  ) => LearningLessonSource(
    SchoolLessonSource(FakeLessonRepository(), progress),
    learning: learning,
    analytics: analytics,
  );

  test(
    'last school lesson completes from progress once, even concurrently',
    () async {
      final progress = FakeSchoolProgressRepository();
      final analytics = FakeAnalyticsRepository();
      final source = school(progress, analytics);
      await source.saveCheckpoint(checkpoint);
      final outcomes = await Future.wait([
        source.complete('mates.queen'),
        source.complete('mates.queen'),
      ]);
      expect(outcomes.first.last, isTrue);
      expect(analytics.eventsNamed('aula_concluida'), hasLength(1));
      final records = await learning.load('a');
      expect(records.single.firstStartedAt, now());
      expect(records.single.contentCompletedAt, now());
      await school(progress, analytics).complete('mates.queen');
      expect(analytics.eventsNamed('aula_concluida'), hasLength(1));
    },
  );

  test(
    'guest session and account switch do not acquire nominal ownership',
    () async {
      final analytics = FakeAnalyticsRepository();
      final progress = FakeSchoolProgressRepository();
      uid = null;
      final guest = school(progress, analytics);
      uid = 'a';
      await guest.saveCheckpoint(checkpoint);
      await guest.complete('mates.queen');
      expect(await learning.load('a'), isEmpty);
      final otherProgress = FakeSchoolProgressRepository();
      final a = school(otherProgress, analytics);
      await a.saveCheckpoint(checkpoint);
      uid = 'b';
      await a.complete('mates.queen');
      expect(await learning.load('b'), isEmpty);
      expect((await learning.load('a')).single.contentCompletedAt, isNull);
    },
  );

  test(
    'legacy and restored progress do not invent starts or completion dates',
    () async {
      final analytics = FakeAnalyticsRepository();
      final restored = FakeSchoolProgressRepository(
        const SchoolProgress(completed: {'mates.queen'}),
      );
      await school(restored, analytics).saveCheckpoint(checkpoint);
      await school(restored, analytics).complete('mates.queen');
      final record = (await learning.load('a')).single;
      expect(record.firstStartedAt, isNull);
      expect(record.contentCompletedAt, isNull);
      expect(analytics.eventsNamed('aula_concluida'), isEmpty);
      // An inherited checkpoint (visitor or a previous account) also has no owner.
      final legacy = FakeSchoolProgressRepository(
        const SchoolProgress(ongoing: checkpoint),
      );
      await school(legacy, analytics).saveCheckpoint(checkpoint);
      await school(legacy, analytics).complete('mates.queen');
      expect((await learning.load('a')).single.contentCompletedAt, isNull);
    },
  );

  test(
    'restored milestone deduplicates completion even without local flags',
    () async {
      final previous = DateTime.utc(2026, 9, 1);
      await learning.restore('a', [
        LearningRecord(
          kind: 'school_lesson',
          unitId: 'mates.queen',
          version: 'v1',
          firstStartedAt: previous,
          contentCompletedAt: previous,
        ),
      ]);
      final analytics = FakeAnalyticsRepository();
      final source = school(FakeSchoolProgressRepository(), analytics);
      await source.saveCheckpoint(checkpoint);
      await source.complete('mates.queen');
      expect(analytics.eventsNamed('aula_concluida'), isEmpty);
      expect((await learning.load('a')).single.contentCompletedAt, previous);
    },
  );

  test(
    'content revision requires actual new checkpoint and completion',
    () async {
      final progress = FakeSchoolProgressRepository();
      final analytics = FakeAnalyticsRepository();
      final v1 = school(progress, analytics);
      await v1.saveCheckpoint(checkpoint);
      await v1.complete('mates.queen');
      revision = 'v2';
      final v2 = school(progress, analytics);
      await v2.saveCheckpoint(checkpoint);
      await v2.complete('mates.queen');
      await v2.complete('mates.queen');
      final records = await learning.load('a');
      expect(records.map((r) => r.version).toSet(), {'v1', 'v2'});
      expect(
        records.every(
          (r) => r.firstStartedAt != null && r.contentCompletedAt != null,
        ),
        isTrue,
      );
      expect(analytics.eventsNamed('aula_concluida'), hasLength(2));
    },
  );

  test(
    'endgame lesson and chapter completion are distinct from test passed',
    () async {
      final analytics = FakeAnalyticsRepository();
      final progress = FakeEndgameProgressRepository();
      final source = LearningLessonSource(
        EndgameLessonSource(FakeEndgameLessonRepository(), progress),
        learning: learning,
        analytics: analytics,
      );
      const cp = LessonCheckpoint(
        lessonId: 'rook.lucena',
        part: 'main',
        step: 0,
      );
      await source.saveCheckpoint(cp);
      await source.completePart('rook.lucena', 'main');
      final records = await learning.load('a');
      expect(records.map((r) => r.kind).toSet(), {
        'endgame_lesson',
        'endgame_chapter',
      });
      expect(
        records.every(
          (r) => r.contentCompletedAt != null && r.testPassedAt == null,
        ),
        isTrue,
      );
      await learning.serial(
        () => learning.observe(
          owner: 'a',
          version: 'v1',
          kind: 'endgame_chapter',
          unitId: 'rook.lucena',
          passed: true,
        ),
      );
      expect(
        (await learning.load('a'))
            .where((r) => r.kind == 'endgame_chapter')
            .single
            .testPassedAt,
        now(),
      );
    },
  );

  test(
    'multipart chapter completes once per revision after every lesson',
    () async {
      final base = FakeEndgameLessonRepository.sample.lessons.first;
      final chapter = EndgameLesson(
        id: base.id,
        module: base.module,
        lesson: Lesson.parted(
          id: base.id,
          parts: const [
            LessonPart(id: 'a', steps: []),
            LessonPart(id: 'b', steps: []),
          ],
        ),
        exercises: base.exercises,
        passScore: base.passScore,
        keyPositions: base.keyPositions,
        practice: base.practice,
      );
      final lessons = FakeEndgameLessonRepository(
        trail: EndgameTrail(
          modules: [
            EndgameModule(id: base.module, lessons: [chapter]),
          ],
        ),
      );
      final progress = FakeEndgameProgressRepository();
      final analytics = FakeAnalyticsRepository();
      for (var i = 0; i < 2; i++) {
        revision = 'v${i + 1}';
        final source = LearningLessonSource(
          EndgameLessonSource(lessons, progress),
          learning: learning,
          analytics: analytics,
        );
        await source.saveCheckpoint(
          LessonCheckpoint(lessonId: base.id, step: 0, part: 'a'),
        );
        await source.completePart(base.id, 'a');
        expect(analytics.eventsNamed('aula_concluida'), hasLength(i));
        await source.saveCheckpoint(
          LessonCheckpoint(lessonId: base.id, step: 0, part: 'b'),
        );
        await source.completePart(base.id, 'b');
        await source.completePart(base.id, 'a');
        expect(analytics.eventsNamed('aula_concluida'), hasLength(i + 1));
      }
      expect(
        (await learning.load('a')).where(
          (r) => r.kind == 'endgame_chapter' && r.contentCompletedAt != null,
        ),
        hasLength(2),
      );
    },
  );

  test(
    'parte antiga não conclui revisão nova ao terminar apenas a parte restante',
    () async {
      final base = FakeEndgameLessonRepository.sample.lessons.first;
      final chapter = EndgameLesson(
        id: base.id,
        module: base.module,
        lesson: Lesson.parted(
          id: base.id,
          parts: const [
            LessonPart(id: 'a', steps: []),
            LessonPart(id: 'b', steps: []),
          ],
        ),
        exercises: base.exercises,
        passScore: base.passScore,
        keyPositions: base.keyPositions,
        practice: base.practice,
      );
      final lessons = FakeEndgameLessonRepository(
        trail: EndgameTrail(
          modules: [
            EndgameModule(id: base.module, lessons: [chapter]),
          ],
        ),
      );
      final progress = FakeEndgameProgressRepository();
      final first = LearningLessonSource(
        EndgameLessonSource(lessons, progress),
        learning: learning,
      );
      await first.saveCheckpoint(
        LessonCheckpoint(lessonId: base.id, step: 0, part: 'a'),
      );
      await first.completePart(base.id, 'a');
      revision = 'v2';
      final second = LearningLessonSource(
        EndgameLessonSource(lessons, progress),
        learning: learning,
      );
      await second.saveCheckpoint(
        LessonCheckpoint(lessonId: base.id, step: 0, part: 'b'),
      );
      await second.completePart(base.id, 'b');
      expect(
        (await learning.load('a'))
            .where((r) => r.kind == 'endgame_chapter' && r.version == 'v2')
            .single
            .contentCompletedAt,
        isNull,
      );
      await second.saveCheckpoint(
        LessonCheckpoint(lessonId: base.id, step: 0, part: 'a'),
      );
      await second.completePart(base.id, 'a');
      expect(
        (await learning.load('a'))
            .where((r) => r.kind == 'endgame_chapter' && r.version == 'v2')
            .single
            .contentCompletedAt,
        now(),
      );
    },
  );

  test(
    'a real school completion closes the matching campaign exactly once',
    () async {
      final analytics = FakeAnalyticsRepository();
      final campaigns = MemoryCampaignRepository();
      await campaigns.remember(
        const Campaign(
          lesson: LinkedLesson(LinkedLessonKind.school, 'mates.queen'),
        ),
      );
      final source = LearningLessonSource(
        SchoolLessonSource(
          FakeLessonRepository(),
          FakeSchoolProgressRepository(),
        ),
        learning: learning,
        analytics: analytics,
        campaigns: campaigns,
      );
      await source.saveCheckpoint(checkpoint);
      await source.complete('mates.queen');
      await source.complete('mates.queen');
      expect(analytics.eventsNamed('campanha_aula_concluida'), hasLength(1));
      expect(await campaigns.active(), isNull);
    },
  );

  test('offline persistence and concurrent restore keep earliest milestones and latest activity', () async {
    final old = DateTime.utc(2026, 10, 1);
    final latest = DateTime.utc(2026, 10, 30);
    await Future.wait([
      learning.serial(
        () => learning.observe(
          owner: 'a',
          version: 'v1',
          kind: 'school_lesson',
          unitId: 'x',
          started: true,
        ),
      ),
      learning.restore('a', [
        LearningRecord(
          kind: 'school_lesson',
          unitId: 'x',
          version: 'v1',
          firstStartedAt: old,
          lastActivityAt: latest,
        ),
      ]),
      learning.serial(
        () => learning.observe(
          owner: 'a',
          version: 'v1',
          kind: 'school_lesson',
          unitId: 'y',
          completed: true,
        ),
      ),
    ]);
    final restarted = LearningRepository(
      PreferencesService(),
      now,
      currentUid: () => uid,
      versionOf: (_, _) async => revision,
    );
    final records = await restarted.load('a');
    expect(records, hasLength(2));
    expect(records.first.firstStartedAt, old);
    expect(records.first.lastActivityAt, latest);
    expect(await restarted.load('b'), isEmpty);
    final summary = ProgressSummary.fromJson(
      ProgressSummary(learningV1: records).toJson(),
    );
    final merged = ProgressMerge.merge(summary, summary);
    expect(
      merged.learningV1.map((r) => r.toJson()),
      records.map((r) => r.toJson()),
    );
    expect(ProgressSummary.fromJson({}).learningV1, isEmpty);
  });
}
