import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await endgames.expectFinalStep();

    await endgames.openSteps();
    await endgames.completeSteps(lesson, play: _play);
    await endgames.backToExercises();
    await endgames.expectLessonDone();
  });

  patrolTest('exercício: o erro e a dica descontam estrelas', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    // Os exercícios mudam com as revisões das aulas: o cenário lê os da aula.
    final first = lesson.exercises.first;
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);

    // A dica mostra a seta do lance e custa a estrela.
    await endgames.startExercises(_lessonId, first.id);
    await endgames.hint();
    endgames.expectHintArrow(first.line.first.accept.first);
    await endgames.solveExercise(first);
    expectText(endgames.earned, _points(0, first.stars));
    // Com erro ou dica, a correção do Viktor vem sozinha.
    expect(endgames.exerciseSpeech, isNotNull);
    await endgames.back();

    // Lance errado e dica num exercício de 2 estrelas: cada um custa uma.
    // Os anteriores entram prontos.
    final index = lesson.exercises.indexWhere(
      (exercise) => exercise.stars == 2,
    );
    final two = lesson.exercises[index];
    await seedEndgameProgress(
      EndgameProgress(
        lessons: {
          _lessonId: EndgameLessonProgress(
            stars: {
              for (final exercise in lesson.exercises.take(index))
                exercise.id: exercise.stars,
            },
          ),
        },
      ),
    );
    await app.restart();
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);
    await endgames.startExercises(_lessonId, two.id);
    await endgames.exerciseMove(_wrongMove);
    await endgames.hint();
    expect(endgames.exerciseSpeech, isNotEmpty);
    await endgames.solveExercise(two);
    expectText(endgames.earned, _points(0, 2));
    await endgames.back();
    final seeded = lesson.exercises
        .take(index)
        .fold(0, (sum, exercise) => sum + exercise.stars);
    final total = lesson.exercises.fold(
      0,
      (sum, exercise) => sum + exercise.stars,
    );
    endgames.expectScore('$seeded of $total points');
  });

  patrolTest('nota abaixo do mínimo: o passo final fica fechado e refazer '
      'zera a nota', ($) async {
    await AppRobot($).open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);

    // Uma dica em cada exercício: cada um perde uma estrela, abaixo do mínimo.
    final total = lesson.exercises.fold(
      0,
      (sum, exercise) => sum + exercise.stars,
    );
    final earned = total - lesson.exercises.length;
    expect(earned, lessThan(lesson.passScore));
    await endgames.solveAll(lesson, hints: 1);
    await endgames.expectFailed();
    endgames.expectScore('$earned of $total points');
    await endgames.expectFinalStep();

    await endgames.redo();
    // Zerada, a nota sai e volta o botão de começar os exercícios.
    await endgames.expectExercisesToStart();
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
    // O último exercício (o de mais lances); os anteriores entram prontos.
    final last = lesson.exercises.last;
    await seedEndgameProgress(
      EndgameProgress(
        lessons: {
          _lessonId: EndgameLessonProgress(
            stars: {
              for (final exercise in lesson.exercises.take(
                lesson.exercises.length - 1,
              ))
                exercise.id: exercise.stars,
            },
          ),
        },
      ),
    );
    await app.restart();
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);
    await endgames.startExercises(_lessonId, last.id);
    await endgames.exerciseMove(last.line.first.accept.first);
    endgames.expectExerciseBoard(_afterFirstTurn);

    await app.restart();
    await endgames.expectExercise(_lessonId, last.id);
    endgames.expectExerciseBoard(_afterFirstTurn);
    await endgames.solveExercise(last, from: 1);
    expectText(endgames.earned, _points(last.stars, last.stars));
  });
}

/// Um lance legal que nenhum exercício de 2 estrelas da aula aceita no
/// começo (o bispo de a6 para b5, no primeiro deles).
const _wrongMove = 'a6b5';

/// O último exercício depois do primeiro lance e da resposta.
const _afterFirstTurn = '8/8/4BKNk/8/8/8/8/8 w - - 2 2';

/// Os pontos como o app escreve ("1 of 1 point", "0 of 2 points").
String _points(int earned, int total) =>
    '$earned of $total ${total == 1 ? 'point' : 'points'}';
