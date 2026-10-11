import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';

const _english = Locale('en', 'US');

/// As três aulas de dama contra torre e, de cada uma, os lances do passo de
/// jogar contra a máquina dos cenários (que responde o mate, se houver, ou o
/// primeiro lance em ordem).
const _lessons = {
  'queen.vsRook.philidor': ['a5a1', 'a1h8'],
  'queen.vsRook.approach': ['d5d1', 'd1d8'],
  'queen.vsRook.thirdRank': ['d5c4', 'c4b5', 'b5c6', 'f7d7'],
};

void main() {
  for (final MapEntry(key: id, value: finish) in _lessons.entries) {
    patrolTest('$id: a lição inteira, todos os exercícios e o passo final '
        'liberado', ($) async {
      await AppRobot($).open(systemLocale: _english);
      final endgames = EndgamesRobot($);
      final lesson = await endgames.lesson(id);
      await endgames.openFromHome();
      await endgames.openLesson(id);
      await endgames.expectFinalStep();

      await endgames.openSteps();
      await endgames.completeSteps(lesson, play: {'finish': finish});
      await endgames.backToExercises();
      await endgames.expectLessonDone();

      // De primeira em todos: nota máxima, acima do mínimo.
      await endgames.solveAll(lesson);
      await endgames.expectPassed();
      await endgames.expectFinalStep();
    });
  }
}
