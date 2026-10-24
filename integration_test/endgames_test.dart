import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/visible_lessons.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:patrol/patrol.dart';

import '../testing/e2e_dependencies.dart';
import 'robots/app_robot.dart';
import 'robots/endgames_robot.dart';
import 'robots/variant.dart';

const _english = Locale('en', 'US');

/// A primeira aula da trilha: o mate de bispo e cavalo pela manobra em W.
const _lessonId = 'rook.lucena';

/// A aula do speedrun do final: a Lucena não tem posição no catálogo, então
/// não tem speedrun. Esta tem (pawn.pawnVsKing.0001).
const _speedrunLessonId = 'pawns.keySquares';

final _hidden = !VisibleLessons.endgameLessonIds.contains(_lessonId);

void main() {
  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('exercício: o erro e a dica descontam estrelas', ($) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_lessonId);
    // Os exercícios mudam com as revisões das aulas: o cenário lê os da aula.
    final first = lesson.exercises.first;
    await endgames.openFromHome();
    await endgames.openLesson(_lessonId);

    // A dica dá a pista sem a seta do lance e custa a estrela.
    await endgames.startExercises(_lessonId, first.id);
    await endgames.hint();
    endgames.expectHintWithoutArrow();
    await endgames.solveExercise(first);
    expectText(endgames.earned, _points(0, first.stars));
    // Com erro ou dica, a correção do Viktor vem sozinha.
    expect(endgames.exerciseSpeech, isNotNull);
    await endgames.back();

    // Dica e lance errado num exercício de 2 estrelas: zera.
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
    await endgames.hint();
    expect(endgames.exerciseSpeech, isNotEmpty);
    // Errar o primeiro lance zera o exercício, com a dica já descontada.
    await endgames.exerciseMove(endgames.wrongFirstMove(two));
    await endgames.solveExercise(two);
    expectText(endgames.earned, _points(0, 2));
    await endgames.back();
    // Em andamento, a aula mostra só quantos foram resolvidos (os pontos
    // contam no fim, com todos).
    endgames.expectSolvedCount(
      '${index + 1} of ${lesson.exercises.length} solved',
    );
  }, skip: _hidden);

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
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
  }, skip: _hidden);

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest('nota mínima alcançada: speedrun do final e treino liberados', (
    $,
  ) async {
    final app = AppRobot($);
    await app.open(systemLocale: _english);
    final endgames = EndgamesRobot($);
    final lesson = await endgames.lesson(_speedrunLessonId);
    await seedEndgameProgress(
      EndgameProgress(
        lessons: {
          _speedrunLessonId: EndgameLessonProgress(
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
    await endgames.openLesson(_speedrunLessonId);
    await endgames.expectPassed();
    await endgames.expectFinalStep();

    await endgames.challengeSpeedrun('180+2');
    await endgames.back();

    await endgames.train();
  }, skip: _hidden);

  // Aula escondida (VisibleLessons): o cenário volta quando ela for liberada.
  patrolTest(
    'fechar à força no meio do exercício: reabre de onde parou, com a dica',
    ($) async {
      final app = AppRobot($);
      await app.open(systemLocale: _english);
      final endgames = EndgamesRobot($);
      final lesson = await endgames.lesson(_lessonId);
      // O exercício que mais vale (a dica custa uma estrela e não zera); os
      // outros entram prontos.
      final open = lesson.exercises.reduce((a, b) => b.stars > a.stars ? b : a);
      expect(open.stars, greaterThan(1));
      await seedEndgameProgress(
        EndgameProgress(
          lessons: {
            _lessonId: EndgameLessonProgress(
              stars: {
                for (final exercise in lesson.exercises)
                  if (exercise != open) exercise.id: exercise.stars,
              },
            ),
          },
        ),
      );
      await app.restart();
      await endgames.openFromHome();
      await endgames.openLesson(_lessonId);
      await endgames.startExercises(_lessonId, open.id);
      await endgames.hint();
      // Com mais de um lance, larga depois do primeiro.
      final midway = open.line.length > 1;
      if (midway) {
        await endgames.exerciseMove(open.line.first.accept.first);
        endgames.expectExerciseBoard(endgames.boardAfterFirstTurn(open));
      }

      // Fechar à força reabre o mesmo exercício, de onde estava e com a dica
      // já descontada.
      await app.restart();
      await endgames.expectExercise(_lessonId, open.id);
      if (midway) {
        endgames.expectExerciseBoard(endgames.boardAfterFirstTurn(open));
      }
      await endgames.solveExercise(open, from: midway ? 1 : 0);
      expectText(endgames.earned, _points(open.stars - 1, open.stars));
    },
    skip: _hidden,
  );
}

/// Os pontos como o app escreve ("1 of 1 point", "0 of 2 points").
String _points(int earned, int total) =>
    '$earned of $total ${total == 1 ? 'point' : 'points'}';
