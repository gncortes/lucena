import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';

const _english = Locale('en', 'US');

/// As três aulas de defesa com a torre (torre contra torre e peão). O aluno
/// defende de brancas e o objetivo é empatar; as lições não têm passo de
/// jogar contra a máquina.
const _lessons = ['rook.philidor', 'rook.backRank', 'rook.shortSide'];

void main() {
  for (final id in _lessons) {
    patrolTest('$id: a lição inteira, todos os exercícios e o passo final '
        'liberado', ($) async {
      await AppRobot($).open(systemLocale: _english);
      final endgames = EndgamesRobot($);
      final lesson = await endgames.lesson(id);
      await endgames.openFromHome();
      await endgames.openLesson(id);
      await endgames.expectFinalLocked();

      await endgames.openSteps();
      await endgames.completeSteps(lesson, play: const {});
      await endgames.backToExercises();
      await endgames.expectLessonDone();

      // De primeira em todos: nota máxima, acima do mínimo.
      await endgames.solveAll(lesson);
      await endgames.expectPassed();
      await endgames.expectFinalStep();
    });
  }
}
