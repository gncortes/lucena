import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  late FakeEndgameProgressRepository progress;

  Future<EndgameLessonCubit> load(String id) async {
    final cubit = EndgameLessonCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: progress,
      journey: FakeJourneyRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load(id, 'en');
    return cubit;
  }

  setUp(() => progress = FakeEndgameProgressRepository());

  test('abre a aula com o speedrun do final e nada feito', () async {
    final state = (await load('rook.lucena')).state;
    expect(state.viktor!.name, 'Viktor');
    expect(state.lessonNumber, 1);
    expect(state.lessonCount, 2);
    expect(state.speedrun!.id, 'ending.queen');
    expect(state.nextLesson, 'rook.philidor');
    expect(state.score, 0);
    expect(state.maxScore, 6);
    expect(state.passScore, 4);
    expect(state.allSolved, isFalse);
    expect(state.passed, isFalse);
    expect(state.nextExercise!.id, 'e01');
    expect(state.lessonOngoing, isFalse);
  });

  test(
    'ao abrir, estrela e exercício aberto de id cortado são apagados',
    () async {
      progress.saved = EndgameProgress(
        lessons: {
          'rook.lucena': const EndgameLessonProgress(
            stars: {'e01': 1, 'e09': 3},
            exercise: ExerciseCheckpoint(exerciseId: 'e09'),
          ),
        },
      );
      final state = (await load('rook.lucena')).state;
      expect(state.score, 1);
      expect(state.solved, 1);
      expect(state.nextExercise!.id, 'e02');
      expect(progress.saved.of('rook.lucena').stars, {'e01': 1});
      expect(progress.saved.of('rook.lucena').exercise, isNull);
    },
  );

  test('a faixa da nota: abaixo, aprovado, bom e perfeito', () async {
    Future<EndgameLessonState> withStars(Map<String, int> stars) async {
      progress.saved = EndgameProgress(
        lessons: {'rook.lucena': EndgameLessonProgress(stars: stars)},
      );
      return (await load('rook.lucena')).state;
    }

    // Aula de 6 estrelas, mínimo 4: 4, 5, 6 (75% e 85% sobem de uma em uma).
    expect((await withStars({'e01': 1})).grade, ExerciseGrade.below);
    final passed = await withStars({'e01': 2, 'e02': 1, 'e03': 1});
    expect(passed.grade, ExerciseGrade.passed);
    expect(passed.gradeStars[ExerciseGrade.passed], 4);
    expect(
      (await withStars({'e01': 2, 'e02': 2, 'e03': 1})).grade,
      ExerciseGrade.good,
    );
    final perfect = await withStars({'e01': 2, 'e02': 2, 'e03': 2});
    expect(perfect.grade, ExerciseGrade.perfect);
    expect(perfect.gradeStars[ExerciseGrade.perfect], 6);
  });

  test('final sem speedrun e última da trilha', () async {
    final state = (await load('rook.philidor')).state;
    expect(state.speedrun, isNull);
    expect(state.nextLesson, isNull);
  });

  test('a lição começada aparece como em andamento', () async {
    progress.saved = const EndgameProgress(
      ongoing: LessonCheckpoint(lessonId: 'rook.lucena', step: 1),
    );
    expect((await load('rook.lucena')).state.lessonOngoing, isTrue);
  });

  test('o exercício aberto é o próximo, mesmo não sendo o primeiro', () async {
    progress.saved = const EndgameProgress(
      lessons: {
        'rook.lucena': EndgameLessonProgress(
          stars: {'e01': 1},
          exercise: ExerciseCheckpoint(exerciseId: 'e03'),
        ),
      },
    );
    expect((await load('rook.lucena')).state.nextExercise!.id, 'e03');
  });

  test('passa com a lição feita e a nota no mínimo', () async {
    progress.saved = const EndgameProgress(
      lessons: {
        'rook.lucena': EndgameLessonProgress(
          lessonDone: true,
          stars: {'e01': 1, 'e02': 1, 'e03': 2},
        ),
      },
    );
    final state = (await load('rook.lucena')).state;
    expect(state.allSolved, isTrue);
    expect(state.passed, isTrue);
    expect(state.nextExercise, isNull);
    expect(state.starsOf('e02'), 1);
  });

  test('sem a lição, a nota não libera o passo final', () async {
    progress.saved = const EndgameProgress(
      lessons: {
        'rook.lucena': EndgameLessonProgress(
          stars: {'e01': 1, 'e02': 2, 'e03': 3},
        ),
      },
    );
    final state = (await load('rook.lucena')).state;
    expect(state.allSolved, isTrue);
    expect(state.passed, isFalse);
  });

  test('refazer os exercícios zera a nota e mantém a lição', () async {
    progress.saved = const EndgameProgress(
      lessons: {
        'rook.lucena': EndgameLessonProgress(
          lessonDone: true,
          stars: {'e01': 1, 'e02': 0, 'e03': 1},
          exercise: ExerciseCheckpoint(exerciseId: 'e01'),
        ),
      },
    );
    final cubit = await load('rook.lucena');
    expect(cubit.state.allSolved, isTrue);
    expect(cubit.state.passed, isFalse);
    await cubit.redoExercises();
    expect(cubit.state.score, 0);
    expect(cubit.state.solved, 0);
    expect(cubit.state.progress.lessonDone, isTrue);
    expect(progress.saved.of('rook.lucena').stars, isEmpty);
    expect(progress.saved.of('rook.lucena').exercise, isNull);
  });

  test('aula que não existe', () async {
    expect((await load('nothing')).state.missing, isTrue);
  });
}
