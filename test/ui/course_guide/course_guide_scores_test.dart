import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';

import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';

void main() {
  for (final fixture in [
    (stars: <String, int>{}, score: null),
    (stars: {'e01': 0}, score: 0),
    (stars: {'e01': 1, 'e02': 2, 'e03': 3}, score: 100),
  ]) {
    test(
      'guide uses operational test score ${fixture.score}, including zero',
      () async {
        final repository = FakeTrainingRepository(
          content: {
            TrainingCourse.pilares: TrainingResources(
              lessons: const [
                TrainingLesson(
                  id: 'rook.lucena',
                  kind: TrainingLessonKind.test,
                  title: 'Lucena',
                ),
                TrainingLesson(
                  id: 'missing',
                  kind: TrainingLessonKind.test,
                  title: 'Missing',
                ),
              ],
            ),
          },
        );
        final cubit = CourseGuideCubit(
          repository: repository,
          config: TrainingCourseConfig.pilares,
          now: FakeNow(DateTime(2026, 10, 29)),
          testLessons: FakeEndgameLessonRepository(),
          testProgress: FakeEndgameProgressRepository(
            EndgameProgress(
              lessons: {
                'rook.lucena': EndgameLessonProgress(stars: fixture.stars),
              },
            ),
          ),
        );
        addTearDown(repository.dispose);
        addTearDown(cubit.close);
        await cubit.load();
        expect(cubit.state.failed, false);
        expect(cubit.state.testScores['rook.lucena'], fixture.score);
        expect(cubit.state.testScores['missing'], isNull);
        await cubit.selectTab(CourseGuideTab.progress);
        expect(cubit.state.testScores['rook.lucena'], fixture.score);
      },
    );
  }
}
