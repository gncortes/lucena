import '../../../domain/models/learning_unit_completion.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/complete_training_lesson.dart';
import 'course_training_repository.dart';

/// Learning owns completion. This adapter only observes explicit, awaited
/// commands and advances a course that has already been started.
final class TrainingLearningBridge {
  const TrainingLearningBridge(
    this.repository, {
    this.courses = const [TrainingCourseConfig.pilares],
  });
  final TrainingRepository repository;
  final List<TrainingCourseConfig> courses;
  Future<void> call(LearningUnitCompletion completion) async {
    if (!const {
      'endgame_lesson',
      'endgame_chapter',
      'school_lesson',
    }.contains(completion.kind)) {
      return;
    }
    final id = completion.kind == 'endgame_lesson'
        ? completion.unitId.replaceAll('/', '.')
        : completion.unitId;
    await Future.wait([
      for (final config in courses)
        repository.transact(config.course, (current) async {
          if (!current.onboardingDone) return current;
          final resources = await repository.resources(config.course);
          final lesson = resources.lessons
              .where((l) => l.visible && l.id == id)
              .firstOrNull;
          if (lesson == null ||
              lesson.kind == TrainingLessonKind.test &&
                  !completion.testPassed) {
            return current;
          }
          if (completion.kind == 'school_lesson' &&
              lesson.kind != TrainingLessonKind.school) {
            return current;
          }
          return CompleteTrainingLesson(_CompletionNow(completion.at), config)(
            current,
            resources,
            lesson,
            redo: current.cycles[lesson.id]?.phase == ThemePhase.redo,
          );
        }),
    ]);
  }
}

final class _CompletionNow implements Now {
  const _CompletionNow(this.at);
  final DateTime at;
  @override
  DateTime call() => at;
}
