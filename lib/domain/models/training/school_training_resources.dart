import '../lesson.dart';
import 'training_content.dart';
import 'training_course.dart';
import 'training_resources.dart';

/// Pass the course already filtered by VisibleLessons.course, and localized texts.
TrainingResources schoolTrainingResources(Course course, LessonTexts texts) =>
    TrainingResources(
      lessons: [
        for (final module in course.modules)
          for (final lesson in module.lessons)
            TrainingLesson(
              id: lesson.id,
              kind: TrainingLessonKind.school,
              title: texts.lessonTitle(lesson.id),
              summary: texts.lessonSummary(lesson.id) ?? '',
              group: texts.moduleTitle(module.id),
              groupId: module.id,
            ),
      ],
    );
