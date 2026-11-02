import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_now.dart';

void main() {
  final clock = FakeNow(DateTime(2026, 10, 30, 12));
  final resources = TrainingResources(
    lessons: const [
      TrainingLesson(id: 'one', kind: TrainingLessonKind.theme, title: 'One'),
      TrainingLesson(
        id: 'two',
        kind: TrainingLessonKind.theme,
        title: 'Two',
        visible: false,
        published: false,
      ),
      TrainingLesson(
        id: 'three',
        kind: TrainingLessonKind.theme,
        title: 'Three',
      ),
    ],
  );
  test(
    'first unpublished item blocks later published lessons and daily quota',
    () {
      final state = TrainingState(
        course: TrainingCourse.pilares,
        installSeed: 'test',
        onboardingDone: true,
        completedLessons: {'one': '2026-10-29'},
      );
      final guide = CourseGuideState(
        training: state,
        resources: resources,
        loading: false,
      );
      expect(guide.nextLesson, isNull);
      expect(guide.awaitingPublication, true);
      final day = BuildDayGoals(clock, TrainingCourseConfig.pilares)(
        state,
        resources,
      ).day!;
      expect(day.goals.where((g) => g.ref == 'three'), isEmpty);
    },
  );

  testWidgets(
    'successful later navigation cancels retry of an earlier failed tab',
    (tester) async {
      final repo = FakeTrainingRepository(
        content: {TrainingCourse.pilares: resources},
      );
      final cubit = CourseGuideCubit(
        repository: repo,
        config: TrainingCourseConfig.pilares,
        now: clock,
      );
      addTearDown(cubit.close);
      addTearDown(repo.dispose);
      await cubit.load();
      repo.writeError = StateError('temporary disk failure');
      expect(await cubit.selectTab(CourseGuideTab.goals), false);
      repo.writeError = null;
      expect(await cubit.selectTab(CourseGuideTab.progress), true);
      await tester.pump(const Duration(seconds: 2));
      expect(
        (await repo.load(TrainingCourse.pilares)).tab,
        CourseGuideTab.progress,
      );
    },
  );
}
