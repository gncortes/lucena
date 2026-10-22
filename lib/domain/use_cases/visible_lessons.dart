import '../models/endgame_lesson.dart';
import '../models/lesson.dart';

/// As aulas liberadas no app (Gabriel, 15/10/2026, antes da versão de QA):
/// só a Oposição (T76: Casas-chave e oposição, Oposição distante e Lances de
/// espera). As outras aulas de finais e a Escola do Viktor ficam escondidas, sem sair dos assets nem do progresso gravado;
/// liberar uma aula é pôr o id aqui.
///
/// Além do id, vale a regra do formato novo (Gabriel, 15/10/2026): um
/// capítulo só aparece se tiver roteiro novo (`LessonPart.script`); a aula
/// sem nenhum capítulo com roteiro sai, e a Escola mostra só a aula com
/// `Lesson.script`. Este arquivo é o único ponto dessa decisão.
abstract final class VisibleLessons {
  /// O capítulo [part] aparece: tem roteiro novo.
  static bool partVisible(LessonPart part) => part.script != null;

  /// A aula [lesson] da Escola aparece: tem roteiro novo.
  static bool schoolLessonVisible(Lesson lesson) => lesson.script != null;

  /// As aulas de finais que aparecem.
  static const endgameLessonIds = {
    'pawns.keySquares',
    'pawns.distantOpposition',
    'pawns.waitingMoves',
    // T77: bispo e cavalo, capítulo a capítulo (só os com roteiro aparecem).
    'mates.bishopKnight.deletang',
    // T78: dama contra torre, do mesmo jeito.
    'queen.vsRook.philidor',
    // T79: final de torre (posição de Lucena), do mesmo jeito.
    'rook.lucena',
  };

  /// Os exercícios que cobrem uma ideia sem capítulo visível (T76): ficam nos
  /// assets e no progresso salvo, mas fora da lista da aula e da nota, até o
  /// capítulo deles voltar. A nota mínima da aula (`passScore`) já vale só
  /// para os exercícios visíveis.
  static const hiddenExercises = <String, Set<String>>{
    // Peão travado (casas-chave de b6) e zugzwang mútuo.
    'pawns.keySquares': {'e15', 'e16'},
    // Corrida de reis com peões na coluna a.
    'pawns.distantOpposition': {'e19'},
  };

  /// As aulas da Escola que aparecem. Vazia: a Escola some do app.
  static const schoolLessonIds = <String>{};

  /// A Escola tem alguma aula liberada.
  static bool get school => schoolLessonIds.isNotEmpty;

  /// [trail] só com as aulas de [ids], na mesma ordem, e delas só os
  /// capítulos com roteiro ([partVisible]); a aula e o módulo que ficam vazios
  /// saem.
  static EndgameTrail trail(
    EndgameTrail trail, [
    Set<String> ids = endgameLessonIds,
  ]) {
    final modules = <EndgameModule>[];
    for (final module in trail.modules) {
      final lessons = [
        for (final lesson in module.lessons)
          if (ids.contains(lesson.id)) ?_withVisibleParts(lesson),
      ];
      if (lessons.isNotEmpty) {
        modules.add(EndgameModule(id: module.id, lessons: lessons));
      }
    }
    return EndgameTrail(modules: modules);
  }

  static EndgameLesson? _withVisibleParts(EndgameLesson lesson) {
    final parts = [...lesson.lesson.parts.where(partVisible)];
    if (parts.isEmpty) return null;
    return EndgameLesson(
      id: lesson.id,
      module: lesson.module,
      lesson: Lesson.parted(
        id: lesson.lesson.id,
        parts: parts,
        script: lesson.lesson.script,
      ),
      exercises: [
        for (final exercise in lesson.exercises)
          if (!(hiddenExercises[lesson.id]?.contains(exercise.id) ?? false))
            exercise,
      ],
      passScore: lesson.passScore,
      keyPositions: lesson.keyPositions,
      practice: lesson.practice,
      references: lesson.references,
      inReview: lesson.inReview,
      failed: lesson.failed,
    );
  }

  /// [course] só com as aulas de [ids], na mesma ordem; o módulo que fica
  /// vazio sai.
  static Course course(Course course, [Set<String> ids = schoolLessonIds]) =>
      Course(
        modules: [
          for (final module in course.modules)
            if (module.lessons.any(
              (lesson) =>
                  ids.contains(lesson.id) && schoolLessonVisible(lesson),
            ))
              CourseModule(
                id: module.id,
                lessons: [
                  for (final lesson in module.lessons)
                    if (ids.contains(lesson.id) && schoolLessonVisible(lesson))
                      lesson,
                ],
              ),
        ],
      );
}
