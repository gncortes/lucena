import '../domain/models/endgame_lesson.dart';
import '../domain/models/lesson.dart';
import '../domain/models/star_challenge.dart';
import 'routes.dart';

/// Onde o app abre: na partida ou na aula que estava na tela quando ele foi
/// fechado, ou no início.
String launchLocation({
  int? conclusion,
  bool resumeGame = false,
  SchoolProgress school = const SchoolProgress(),
  EndgameProgress endgames = const EndgameProgress(),
  OpenStarChallenge? stars,
}) {
  final lesson = school.ongoing;
  final endgameLesson = endgames.ongoing;
  final exercise = endgames.openExercise;
  if (conclusion != null) return Routes.conclusion(conclusion);
  if (resumeGame) return Routes.freeBoard;
  if (lesson != null && lesson.open) return Routes.lesson(lesson.lessonId);
  if (endgameLesson != null && endgameLesson.open) {
    // Com a parte: a parte com roteiro vai direto para a tela de roteiro (o
    // redirect da rota), que grava o checkpoint com ela.
    return Routes.endgameLessonSteps(
      endgameLesson.lessonId,
      part: endgameLesson.part,
    );
  }
  if (exercise != null) {
    return Routes.endgameExercise(exercise.$1, exercise.$2.exerciseId);
  }
  if (stars != null) {
    return Routes.starChallenge(stars.piece.name, stars.level.name);
  }
  return Routes.home;
}
