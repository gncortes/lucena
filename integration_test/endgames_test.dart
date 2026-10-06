import 'package:flutter/widgets.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/variant.dart';

const _english = Locale('en', 'US');

/// A primeira aula da trilha: o mate de bispo e cavalo pela manobra em W.
const _lessonId = 'mates.bishopKnight.w';

/// Os passos de jogar da lição contra a máquina dos cenários, que responde
/// sempre o mesmo (o mate, se houver, ou o primeiro lance em ordem).
const _play = {
  'playW': ['d3g6', 'g6f7', 'e5d7'],
  'playFar': ['e6e7', 'e7d6', 'd3c5', 'c5e6', 'e4g6'],
};

void main() {
  patrolTest('aula de final: a lição inteira e a volta à aula marcada', (
    $,
  ) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);
    await endgames.expectFinalLocked();

    await endgames.openSteps();
    await endgames.completeSteps(lesson, play: _play);
    await endgames.backToExercises();
    await endgames.expectLessonDone();
  });

  patrolTest('exercício: o erro e a dica descontam estrelas', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);

    // Lance errado: o Viktor dá a pista e a estrela vai embora.
    await endgames.openExercise(_lessonId, 'e05');
    await endgames.exerciseMove('h7g8');
    expectText(
      endgames.exerciseSpeech,
      "The square d7 is dark: the knight's job. From where does it cover d7 "
      'and still stay on the path of the W?',
    );
    await endgames.solveExercise(lesson.exercise('e05')!);
    expectText(endgames.earned, '1 of 2 stars');
    await endgames.back();
    endgames.expectExerciseStars('e05', 1);

    // A dica mostra a seta do lance e também custa a estrela.
    await endgames.openExercise(_lessonId, 'e01');
    await endgames.hint();
    endgames.expectHintArrow('f1g2');
    await endgames.solveExercise(lesson.exercise('e01')!);
    expectText(endgames.earned, '0 of 1 stars');
  });

  patrolTest('nota abaixo do mínimo: o passo final fica fechado e refazer '
      'zera a nota', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);

    // Uma dica em cada exercício: 11 das 23 estrelas, abaixo das 14.
    await endgames.solveAll(lesson, hints: 1);
    await endgames.expectFailed();
    endgames.expectScore('11 of 23 stars');
    await endgames.expectFinalLocked();

    await endgames.redo();
    endgames.expectScore('0 of 23 stars');
    endgames.expectNotFailed();
  });

  patrolTest('nota mínima alcançada: speedrun do final e treino liberados', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    await seedEndgameProgress(
      EndgameProgress(
        lessons: {
          _lessonId: EndgameLessonProgress(
            lessonDone: true,
            stars: {
              for (final exercise in lesson.exercises)
                exercise.id: exercise.stars,
            },
          ),
        },
      ),
    );
    await app.restart();
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);
    await endgames.expectPassed();
    await endgames.expectFinalStep();

    await endgames.challengeSpeedrun('180+2');
    await endgames.back();

    await endgames.train();
  });

  patrolTest('fechar à força no meio do exercício: reabre no mesmo lance', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);
    await endgames.openExercise(_lessonId, 'e06');
    await endgames.exerciseMove('d1g4');
    endgames.expectExerciseBoard('1k6/8/1K6/2N5/6B1/8/8/8 w - - 2 2');

    await app.restart();
    await endgames.expectExercise(_lessonId, 'e06');
    endgames.expectExerciseBoard('1k6/8/1K6/2N5/6B1/8/8/8 w - - 2 2');
    await endgames.solveExercise(lesson.exercise('e06')!, from: 1);
    expectText(endgames.earned, '2 of 2 stars');
  });
}
