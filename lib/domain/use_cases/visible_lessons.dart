import '../models/endgame_lesson.dart';
import '../models/lesson.dart';

/// As aulas liberadas no app (Gabriel, 15/10/2026, antes da versão de QA):
/// só a Oposição, Partes 1 e 2. As outras aulas de finais e a Escola do
/// Viktor ficam escondidas, sem sair dos assets nem do progresso gravado;
/// liberar uma aula é pôr o id aqui.
abstract final class VisibleLessons {
  /// As aulas de finais que aparecem.
  static const endgameLessonIds = {
    'pawns.distantOpposition',
    'pawns.waitingMoves',
  };

  /// As aulas da Escola que aparecem. Vazia: a Escola some do app.
  static const schoolLessonIds = <String>{};

  /// O roteiro do teste de nível mostra os passos "em breve" (aula que não
  /// existe). Desligado enquanto há aulas escondidas: o roteiro mostraria
  /// como "em breve" aula que existe. Volta quando todas forem liberadas.
  static const roadmapSoon = false;

  /// A Escola tem alguma aula liberada.
  static bool get school => schoolLessonIds.isNotEmpty;

  /// [trail] só com as aulas de [ids], na mesma ordem; o módulo que fica
  /// vazio sai.
  static EndgameTrail trail(
    EndgameTrail trail, [
    Set<String> ids = endgameLessonIds,
  ]) => EndgameTrail(
    modules: [
      for (final module in trail.modules)
        if (module.lessons.any((lesson) => ids.contains(lesson.id)))
          EndgameModule(
            id: module.id,
            lessons: [
              for (final lesson in module.lessons)
                if (ids.contains(lesson.id)) lesson,
            ],
          ),
    ],
  );

  /// [course] só com as aulas de [ids], na mesma ordem; o módulo que fica
  /// vazio sai.
  static Course course(Course course, [Set<String> ids = schoolLessonIds]) =>
      Course(
        modules: [
          for (final module in course.modules)
            if (module.lessons.any((lesson) => ids.contains(lesson.id)))
              CourseModule(
                id: module.id,
                lessons: [
                  for (final lesson in module.lessons)
                    if (ids.contains(lesson.id)) lesson,
                ],
              ),
        ],
      );
}
