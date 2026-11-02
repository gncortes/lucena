import '../../../domain/models/learning_unit_completion.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/complete_training_lesson.dart';
import '../../../domain/use_cases/training/training_date.dart';
import 'course_training_repository.dart';

/// Learning owns completion. This adapter only observes explicit, awaited
/// commands. Before the plan it records the completion without freezing a day.
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
          if (!current.onboardingDone) {
            if (current.completedLessons.containsKey(lesson.id) &&
                !current.bootstrapImports.containsKey(lesson.id)) {
              return current;
            }
            final date = trainingDate(completion.at.toLocal());
            final next = config.followUps.lessonCompleted(
              current,
              lesson,
              date,
            );
            return next.copyWith(
              completedLessons: {...next.completedLessons, lesson.id: date},
              bootstrapImports: {...next.bootstrapImports}..remove(lesson.id),
              lastActivityAt: completion.at,
            );
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
