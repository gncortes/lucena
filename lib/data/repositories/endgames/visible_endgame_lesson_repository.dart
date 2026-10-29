import '../../../domain/models/endgame_lesson.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/visible_lessons.dart';
import 'endgame_lesson_repository.dart';

/// As aulas de finais do app: as de [VisibleLessons.endgameLessonIds], por
/// cima de todas as dos assets. Quem pede uma aula escondida recebe nula
/// (a tela de aula que não existe).
class VisibleEndgameLessonRepository implements EndgameLessonRepository {
  VisibleEndgameLessonRepository(
    this._all, {
    this.ids = VisibleLessons.endgameLessonIds,
  });

  final EndgameLessonRepository _all;
  final Set<String> ids;

  @override
  Future<EndgameTrail> trail() =>
      _all.trail().then((all) => VisibleLessons.trail(all, ids));

  @override
  Future<LessonTexts> texts(String language) => _all.texts(language);
}
