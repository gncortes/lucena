import 'package:flutter/widgets.dart';
import 'package:patrol/patrol.dart';

import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';

const _english = Locale('en', 'US');

/// As três aulas de defesa com a torre (torre contra torre e peão). O aluno
/// defende de brancas e o objetivo é empatar; as lições não têm passo de
/// jogar contra a máquina.
const _lessons = ['rook.philidor', 'rook.backRank', 'rook.shortSide'];

// O passo final (T51) é segurar o empate contra a máquina dos cenários:
// estes lances ganham o peão dela, e sem peões o empate conta.
const _finish = {
  'rook.philidor': ['e1f1', 'b1e1', 'e1e4'],
  'rook.backRank': ['g1h1', 'b1g1', 'g1g3'],
  'rook.shortSide': ['a8e8', 'e8e4'],
};

void main() {
  for (final id in _lessons) {
    patrolTest('$id: a lição inteira, todos os exercícios e o passo final '
        'liberado', ($) async {
      await AppRobot($).open(systemLocale: _english);
      final endgames = EndgamesRobot($);
      final lesson = await endgames.lesson(id);
      await endgames.openFromHome();
      await endgames.openLesson(id);
      await endgames.expectFinalStep();

      await endgames.openSteps();
      await endgames.completeSteps(lesson, play: {'finish': _finish[id]!});
      await endgames.backToExercises();
      await endgames.expectLessonDone();

      // De primeira em todos: nota máxima, acima do mínimo.
      await endgames.solveAll(lesson);
      await endgames.expectPassed();
      await endgames.expectFinalStep();
    });
  }
}
