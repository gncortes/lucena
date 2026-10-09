import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  final trail = FakeEndgameLessonRepository.sample;
  final lucena = trail.lesson('rook.lucena')!;

  test('acerto de primeira vale todas as estrelas; erro e dica tiram uma', () {
    expect(EndgameLessonRules.earned(3, mistakes: 0, hints: 0), 3);
    expect(EndgameLessonRules.earned(3, mistakes: 1, hints: 0), 2);
    expect(EndgameLessonRules.earned(3, mistakes: 1, hints: 1), 1);
    expect(EndgameLessonRules.earned(1, mistakes: 2, hints: 1), 0);
  });

  test('a nota passa com todos resolvidos e a soma no mínimo', () {
    expect(lucena.maxScore, 6);
    const partial = EndgameLessonProgress(stars: {'e01': 1, 'e02': 2});
    expect(EndgameLessonRules.allSolved(lucena, partial), isFalse);
    expect(EndgameLessonRules.passed(lucena, partial), isFalse);

    const low = EndgameLessonProgress(
      lessonDone: true,
      stars: {'e01': 1, 'e02': 1, 'e03': 1},
    );
    expect(low.scoreOf(lucena), 3);
    expect(EndgameLessonRules.allSolved(lucena, low), isTrue);
    expect(EndgameLessonRules.passed(lucena, low), isFalse);

    const enough = EndgameLessonProgress(
      lessonDone: true,
      stars: {'e01': 1, 'e02': 0, 'e03': 3},
    );
    expect(EndgameLessonRules.passed(lucena, enough), isTrue);
    // Sem a lição feita, a nota sozinha não aprova.
    const noLesson = EndgameLessonProgress(
      stars: {'e01': 1, 'e02': 2, 'e03': 3},
    );
    expect(EndgameLessonRules.passed(lucena, noLesson), isFalse);
  });

  test('estrela de exercício que saiu da aula não conta na nota', () {
    const progress = EndgameLessonProgress(
      lessonDone: true,
      stars: {'e01': 1, 'e02': 0, 'e03': 1, 'e09': 3},
    );
    expect(progress.scoreOf(lucena), 2);
    expect(progress.solvedOf(lucena), 3);
    expect(EndgameLessonRules.allSolved(lucena, progress), isTrue);
    // Sem as 3 estrelas órfãs a nota não chega ao mínimo 4.
    expect(EndgameLessonRules.passed(lucena, progress), isFalse);
  });

  test('prune tira a estrela e o exercício aberto de id cortado', () {
    const clean = EndgameLessonProgress(
      stars: {'e01': 1},
      exercise: ExerciseCheckpoint(exerciseId: 'e02'),
    );
    expect(identical(EndgameLessonRules.prune(lucena, clean), clean), isTrue);

    const dirty = EndgameLessonProgress(
      lessonDone: true,
      parts: {'main'},
      stars: {'e01': 1, 'e09': 3},
      exercise: ExerciseCheckpoint(exerciseId: 'e09', turn: 1),
    );
    final pruned = EndgameLessonRules.prune(lucena, dirty);
    expect(pruned.stars, {'e01': 1});
    expect(pruned.exercise, isNull);
    expect(pruned.lessonDone, isTrue);
    expect(pruned.parts, {'main'});

    // Exercício aberto que ainda existe fica; só a estrela órfã sai.
    const half = EndgameLessonProgress(
      stars: {'e09': 3},
      exercise: ExerciseCheckpoint(exerciseId: 'e02'),
    );
    expect(EndgameLessonRules.prune(lucena, half).exercise?.exerciseId, 'e02');
  });

  test('o speedrun do final é o da posição do treino', () {
    expect(
      EndgameLessonRules.speedrunOf(lucena, sampleSpeedruns)?.id,
      'ending.queen',
    );
    expect(
      EndgameLessonRules.speedrunOf(
        trail.lesson('rook.philidor')!,
        sampleSpeedruns,
      ),
      isNull,
    );
  });

  test('a próxima aula é a primeira sem lição ou sem nota', () {
    expect(
      EndgameLessonRules.next(trail, const EndgameProgress())?.id,
      'rook.lucena',
    );
    final lessonOnly = EndgameProgress(
      lessons: {'rook.lucena': const EndgameLessonProgress(lessonDone: true)},
    );
    expect(EndgameLessonRules.next(trail, lessonOnly)?.id, 'rook.lucena');
    final passed = EndgameProgress(
      lessons: {
        'rook.lucena': const EndgameLessonProgress(
          lessonDone: true,
          stars: {'e01': 1, 'e02': 2, 'e03': 3},
        ),
      },
    );
    expect(EndgameLessonRules.next(trail, passed)?.id, 'rook.philidor');
    final all = passed.withLesson(
      'rook.philidor',
      const EndgameLessonProgress(lessonDone: true, stars: {'e01': 1}),
    );
    expect(EndgameLessonRules.next(trail, all), isNull);
  });

  test('a solução em notação: o lance ensinado e a resposta de cada vez', () {
    final lesson = FakeEndgameLessonRepository.sample.lesson('rook.lucena')!;
    final e02 = lesson.exercises.firstWhere((e) => e.id == 'e02');
    expect(EndgameLessonRules.solution(e02), ['Rc4', 'Ra1', 'Rc5']);
    expect(
      EndgameLessonRules.solution(
        const Exercise(
          id: 'x',
          stars: 1,
          fen: 'not a fen',
          goal: PositionGoal.win,
          origin: 'own',
          line: [],
        ),
      ),
      isEmpty,
    );
  });
}
