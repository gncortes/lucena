import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';

import '../../testing/training/training_fixture_preferences.dart';

void main() {
  test(
    'the host course cannot overwrite the manually mounted real bank',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final store = PreferencesService();
      final host = TrainingRepositoryLocal(
        store,
        const LessonContentAssets(),
        installSeed: 'host',
      );
      final fixture = TrainingRepositoryLocal(
        TrainingFixturePreferences('real-bank', delegate: store),
        const LessonContentAssets(),
        installSeed: 'fixture',
      );
      addTearDown(host.dispose);
      addTearDown(fixture.dispose);
      await host.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(completedLessons: {'mock': '2026-10-29'}),
      );
      await fixture.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(completedLessons: {'real': '2026-10-29'}),
      );
      await host.update(
        TrainingCourse.pilares,
        (s) => s.copyWith(completedLessons: {'mock': '2026-10-30'}),
      );
      final actual = await fixture.load(TrainingCourse.pilares);
      expect(actual.completedLessons, {'real': '2026-10-29'});
      expect(actual.installSeed, 'fixture');
      expect((await host.load(TrainingCourse.pilares)).installSeed, 'host');
    },
  );
}
