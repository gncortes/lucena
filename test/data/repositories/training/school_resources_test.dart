import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/training/school_training_resources.dart';
import 'package:lucena/domain/models/training/school_training_progress.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/training/training_scenario_builder.dart';

void main() {
  final resources = schoolTrainingResources(
    const Course(
      modules: [
        CourseModule(
          id: 'pieces',
          lessons: [
            Lesson(id: 'pieces.rook', steps: []),
            Lesson(id: 'pieces.bishop', steps: []),
            Lesson(id: 'pieces.knight', steps: []),
            Lesson(id: 'pieces.queen', steps: []),
            Lesson(id: 'pieces.king', steps: []),
            Lesson(id: 'pieces.pawn', steps: []),
          ],
        ),
        CourseModule(
          id: 'firstMates',
          lessons: [
            Lesson(id: 'mates.twoRooks', steps: []),
            Lesson(id: 'mates.queen', steps: []),
          ],
        ),
      ],
    ),
    const LessonTexts({
      'module.pieces': ['As peças'],
      'pieces.rook.title': ['A torre'],
      'pieces.rook.summary': ['Como a torre anda.'],
    }),
  );
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  test('adapter preserves source order, filtered lessons, module identity and localized metadata', () {
    expect(resources.lessons.length, 8);
    expect(resources.lessons.first.title, 'A torre');
    expect(resources.lessons.first.summary, 'Como a torre anda.');
    expect(resources.lessons.first.group, 'As peças');
    expect(resources.lessons.first.groupId, 'pieces');
    expect(resources.lessons.last.groupId, 'firstMates');
    expect(
      resources.lessons.every(
        (l) => l.kind == TrainingLessonKind.school && l.visible,
      ),
      isTrue,
    );
    expect(resources.banks, isEmpty);
    expect(resources.openings, isEmpty);
    expect(
      schoolTrainingResources(
        const Course(modules: []),
        LessonTexts.empty,
      ).lessons,
      isEmpty,
    );
  });
  test('injected content source avoids course-specific parsing; courses persist independently', () async {
    final preferences = PreferencesService();
    TrainingRepositoryLocal reopen() => TrainingRepositoryLocal(
      preferences,
      const LessonContentAssets(),
      installSeed: 'source-test',
      configs: const {
        TrainingCourse.pilares: TrainingCourseConfig.pilares,
        TrainingCourse.escola: TrainingCourseConfig.escola,
      },
      contentSources: {
        TrainingCourseConfig.escola.indexSource: () async => resources,
      },
    );
    final repository = reopen();
    addTearDown(repository.dispose);
    expect(
      (await repository.resources(TrainingCourse.escola)).lessons.length,
      8,
    );
    await repository.update(
      TrainingCourse.escola,
      (s) => s.copyWith(
        school: SchoolTrainingProgress(
          pieceLevels: {'rook': 2},
          pieceAdvancedOn: {'rook': '2026-10-26'},
        ),
      ),
    );
    await repository.update(
      TrainingCourse.pilares,
      (s) => s.copyWith(onboardingDone: true),
    );
    final restored = reopen();
    addTearDown(restored.dispose);
    expect(
      (await restored.load(TrainingCourse.escola)).school.pieceLevels['rook'],
      2,
    );
    expect(
      (await restored.load(TrainingCourse.pilares)).school.pieceLevels,
      isEmpty,
    );
    expect(
      (await restored.load(TrainingCourse.escola)).onboardingDone,
      isFalse,
    );
  });
  test('builder uses injected school resources for quotas, pieces, mates, off day and double', () {
    final scenario = TrainingScenarioBuilder(
      TrainingCourse.escola,
      resources: resources,
    );
    expect(scenario.schoolDayOne().day!.goals.length, 4);
    expect(
      scenario.schoolPieces().day!.goals.where((g) => g.kind == GoalKind.stars),
      hasLength(5),
    );
    expect(
      scenario.schoolMates().day!.goals.where((g) => g.kind == GoalKind.bot),
      hasLength(2),
    );
    expect(
      scenario.schoolMates().day!.goals.where(
        (g) => g.kind == GoalKind.speedrun,
      ),
      hasLength(1),
    );
    expect(
      scenario
          .schoolMates(completedBots: true)
          .day!
          .goals
          .where((g) => g.kind == GoalKind.bot || g.kind == GoalKind.speedrun),
      isEmpty,
    );
    expect(scenario.schoolOffDay().day!.goals, isEmpty);
    expect(
      scenario.schoolTwoHours().day!.goals.length,
      8,
    ); // clipped to actual source
    expect(scenario.schoolAllDone().day!.allDone, isTrue);
    expect(scenario.doubled().day!.doubled, isTrue);
  });
}
