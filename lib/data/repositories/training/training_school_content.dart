import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/visible_lessons.dart';
import '../school/lesson_repository.dart';

/// Private validation source for training routes. The existing public school
/// repository and the release whitelist remain unchanged.
final class TrainingSchoolContent implements LessonRepository {
  const TrainingSchoolContent(this.inner, {this.includeAll = false});
  final LessonRepository inner;
  final bool includeAll;
  @override
  Future<Course> course() async {
    final all = await inner.course();
    return VisibleLessons.course(
      all,
      includeAll
          ? all.lessons.map((l) => l.id).toSet()
          : VisibleLessons.schoolLessonIds,
    );
  }

  @override
  Future<LessonTexts> texts(String language) => inner.texts(language);
}
