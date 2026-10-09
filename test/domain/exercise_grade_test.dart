import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';

/// As faixas da nota dos exercícios de uma aula de final.
void main() {
  // Dez exercícios, 18 estrelas, mínimo 11: o caso da aula de ruptura.
  final lesson = EndgameLesson(
    id: 'pawns.breakthrough',
    module: 'pawns',
    lesson: const Lesson(id: 'pawns.breakthrough', steps: []),
    exercises: [
      for (var index = 0; index < 10; index++)
        Exercise(
          id: 'e$index',
          stars: index < 8 ? 2 : 1,
          fen: '8/8/8/8/8/8/8/K6k w - - 0 1',
          goal: PositionGoal.win,
          line: const [],
        ),
    ],
    passScore: 11,
    keyPositions: const [],
    practice: const Practice(
      fen: '8/8/8/8/8/8/8/K6k w - - 0 1',
      goal: PositionGoal.win,
    ),
  );

  test('as estrelas de cada faixa sobem do mínimo ao total', () {
    expect(EndgameLessonRules.gradeStars(lesson), {
      ExerciseGrade.passed: 11,
      ExerciseGrade.good: 14,
      ExerciseGrade.excellent: 16,
      ExerciseGrade.perfect: 18,
    });
  });

  test('16 de 18 é excelente; 18 é perfeito; 10 não passa', () {
    expect(EndgameLessonRules.grade(lesson, 10), ExerciseGrade.below);
    expect(EndgameLessonRules.grade(lesson, 11), ExerciseGrade.passed);
    expect(EndgameLessonRules.grade(lesson, 15), ExerciseGrade.good);
    expect(EndgameLessonRules.grade(lesson, 16), ExerciseGrade.excellent);
    expect(EndgameLessonRules.grade(lesson, 17), ExerciseGrade.excellent);
    expect(EndgameLessonRules.grade(lesson, 18), ExerciseGrade.perfect);
  });
}
