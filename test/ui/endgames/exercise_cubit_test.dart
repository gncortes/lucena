import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';

void main() {
  late FakeEndgameProgressRepository progress;

  ExerciseCubit cubit() {
    final cubit = ExerciseCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: progress,
      characters: FakeCharacterRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Move move(String uci) => Move.parse(uci)!;

  setUp(() => progress = FakeEndgameProgressRepository());

  test('abre com o enunciado e grava o exercício aberto', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e01', 'en');
    final state = exercise.state;
    expect(state.viktor!.name, 'Viktor');
    expect(state.speech, 'White to play and win.');
    expect(state.number, 1);
    expect(state.count, 3);
    expect(state.nextExercise, 'e02');
    expect(state.fen, FakeEndgameLessonRepository.lucenaFen);
    final saved = progress.saved.of('rook.lucena').exercise!;
    expect(saved.exerciseId, 'e01');
    expect(saved.open, isTrue);
  });

  test(
    'acerto de primeira vale todas as estrelas e mostra a solução',
    () async {
      final exercise = cubit();
      await exercise.load('rook.lucena', 'e03', 'en');
      await exercise.play(move('c1c4'));
      final state = exercise.state;
      expect(state.phase, ExercisePhase.done);
      expect(state.earned, 3);
      expect(state.speech, 'Same bridge.');
      expect(state.emotion, Emotion.happy);
      expect(progress.saved.of('rook.lucena').stars, {'e03': 3});
      expect(progress.saved.of('rook.lucena').exercise, isNull);
      // Os outros ainda estão por resolver: o próximo é o primeiro deles.
      expect(state.nextExercise, 'e01');
    },
  );

  test('erro e dica tiram uma estrela cada; a peça volta', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    expect(exercise.state.mistakes, 1);
    expect(exercise.state.fen, FakeEndgameLessonRepository.lucenaFen);
    expect(exercise.state.speech, 'Same idea.');
    expect(exercise.state.hint, isNull);

    await exercise.askHint();
    expect(exercise.state.hints, 1);
    expect(exercise.state.hint, move('c1c4'));
    // A mesma dica de novo não custa outra estrela.
    await exercise.askHint();
    expect(exercise.state.hints, 1);

    await exercise.play(move('c1c4'));
    expect(exercise.state.earned, 1);
    expect(progress.saved.of('rook.lucena').stars, {'e03': 1});
  });

  test('a resposta do outro lado vem sozinha, e a vez avança', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c4'));
    expect(exercise.state.turn, 1);
    expect(exercise.state.lastMove, move('a2a1'));
    expect(exercise.state.phase, ExercisePhase.active);
    await exercise.play(move('c4c5'));
    expect(exercise.state.phase, ExercisePhase.done);
    expect(exercise.state.earned, 2);
  });

  test('outro lance bom que não o ensinado resolve o exercício ali', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c5'));
    final state = exercise.state;
    // A resposta e a vez seguinte valem só para o lance ensinado.
    expect(state.phase, ExercisePhase.done);
    expect(state.lastMove, move('c1c5'));
    expect(state.earned, 2);
    expect(progress.saved.of('rook.lucena').stars, {'e02': 2});
  });

  test('fechar no meio volta no mesmo exercício, com os erros', () async {
    final first = cubit();
    await first.load('rook.lucena', 'e02', 'en');
    await first.play(move('c1c2'));
    await first.play(move('c1c4'));

    final reopened = cubit();
    await reopened.load('rook.lucena', 'e02', 'en');
    expect(reopened.state.turn, 1);
    expect(reopened.state.mistakes, 1);
    expect(reopened.state.fen, first.state.fen);
  });

  test(
    'sair pelo voltar guarda o exercício, mas o app não reabre nele',
    () async {
      final exercise = cubit();
      await exercise.load('rook.lucena', 'e01', 'en');
      await exercise.leave();
      final saved = progress.saved.of('rook.lucena').exercise!;
      expect(saved.exerciseId, 'e01');
      expect(saved.open, isFalse);
      expect(progress.saved.openExercise, isNull);
    },
  );

  test('exercício que não existe', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e99', 'en');
    expect(exercise.state.missing, isTrue);
  });

  test('com os outros resolvidos, não há próximo', () async {
    progress.saved = const EndgameProgress(
      lessons: {
        'rook.lucena': EndgameLessonProgress(stars: {'e01': 1, 'e02': 2}),
      },
    );
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    expect(exercise.state.nextExercise, isNull);
  });
}
