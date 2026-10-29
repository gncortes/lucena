import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/visible_lessons.dart';
import 'lesson_repository.dart';

/// As aulas da Escola no app: as de [VisibleLessons.schoolLessonIds], por
/// cima de todas as dos assets. As falas comuns (`coach.*`, `module.*`)
/// continuam todas.
class VisibleLessonRepository implements LessonRepository {
  VisibleLessonRepository(
    this._all, {
    this.ids = VisibleLessons.schoolLessonIds,
  });

  final LessonRepository _all;
  final Set<String> ids;

  @override
  Future<Course> course() =>
      _all.course().then((all) => VisibleLessons.course(all, ids));

  @override
  Future<LessonTexts> texts(String language) => _all.texts(language);
}
