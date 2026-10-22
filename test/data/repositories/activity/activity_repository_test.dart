import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/activity/activity_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_activity_repository.dart';
import '../../../../testing/fakes/fake_featured_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';

void main() {
  late FakeNow now;
  late FakeProgressRepository progress;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = FakeNow(DateTime(2026, 10, 22, 21, 30));
    progress = FakeProgressRepository();
  });

  LocalActivityRepository reopen() =>
      LocalActivityRepository(PreferencesService(), progress, now);

  test('o dia marcado fica gravado, uma vez só', () async {
    await reopen().markToday();
    await reopen().markToday();
    now.advance(const Duration(days: 1));
    await reopen().markToday();

    expect(await reopen().days(), {
      DateTime(2026, 10, 22),
      DateTime(2026, 10, 23),
    });
  });

  test('os dias das partidas gravadas entram sem marcar', () async {
    progress.attempts.add(
      Attempt(
        positionId: 'kq_k',
        playedAt: DateTime(2026, 10, 20, 23, 50),
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
      ),
    );

    expect(await reopen().days(), {DateTime(2026, 10, 20)});
  });

  test('a folha da sequência perdida sai uma vez por sequência', () async {
    final end = DateTime(2026, 10, 20);
    expect(await reopen().lostPending(end), isTrue);
    await reopen().markLostShown(end);
    expect(await reopen().lostPending(end), isFalse);
    expect(await reopen().lostPending(DateTime(2026, 10, 25)), isTrue);
  });

  test('aula marca o dia só quando termina', () async {
    final activity = FakeActivityRepository();
    final school = ActiveSchoolProgressRepository(
      FakeSchoolProgressRepository(),
      activity,
    );

    await school.save(
      const SchoolProgress(
        ongoing: LessonCheckpoint(lessonId: 'oposicao', step: 2),
      ),
    );
    expect(activity.marked, isEmpty);

    await school.save(const SchoolProgress(completed: {'oposicao'}));
    expect(activity.marked, {DateTime(2026, 10, 22)});
  });

  test('final em destaque marca o dia mesmo já jogado', () async {
    final activity = FakeActivityRepository();
    final inner = FakeFeaturedProgressRepository()..playedIds.add('f1');
    await ActiveFeaturedProgressRepository(inner, activity).markPlayed('f1');

    expect(activity.marked, {DateTime(2026, 10, 22)});
  });
}
