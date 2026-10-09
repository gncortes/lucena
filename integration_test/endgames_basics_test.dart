import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';

const _english = Locale('en', 'US');

/// Uma aula do módulo de finais básicos, inteira. Os lances do passo de
/// jogar foram calculados contra a máquina dos cenários (que responde o
/// mate, se houver, ou o primeiro lance em ordem), com a tabela de finais.
void main() {
  patrolTest('basics.queenMate: a lição inteira, todos os exercícios e o '
      'passo final liberado', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson('basics.queenMate');
    await endgames.openFromHome();
    await endgames.openLesson('basics.queenMate');
    await endgames.expectFinalStep();

    await endgames.openSteps();
    await endgames.completeSteps(
      lesson,
      play: {
        'finish': ['a1a6', 'a6e6', 'e6d5', 'd5b5', 'e1d1', 'd1c1', 'b5b2'],
      },
    );
    await endgames.backToExercises();
    await endgames.expectLessonDone();

    await endgames.solveAll(lesson);
    await endgames.expectPassed();
    await endgames.expectFinalStep();
  });
}
