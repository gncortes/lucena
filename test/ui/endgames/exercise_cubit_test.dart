import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';

import 'package:lucena/domain/models/game_sound.dart';
import 'package:lucena/ui/core/sound/game_sounds.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_sound_repository.dart';

void main() {
  late FakeEndgameProgressRepository progress;
  late FakeSoundRepository sound;
  late FakeNow now;

  ExerciseCubit cubit() {
    final cubit = ExerciseCubit(
      now: now,
      lessons: FakeEndgameLessonRepository(),
      progress: progress,
      characters: FakeCharacterRepository(),
      sounds: GameSounds(FakeSettingsRepository(), sound),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Move move(String uci) => Move.parse(uci)!;

  setUp(() {
    progress = FakeEndgameProgressRepository();
    sound = FakeSoundRepository();
    now = FakeNow(DateTime.utc(2026, 10, 9, 20));
  });

  test(
    'T60: resolvendo até a resposta, com o cronômetro contando sem limite; '
    'resolvido de primeira, o tabuleiro fica; a explicação, a pedido',
    () async {
      final exercise = cubit();
      await exercise.load('rook.lucena', 'e03', 'en');
      expect(exercise.state.layout, ExerciseLayoutMode.solving);
      expect(exercise.elapsed, Duration.zero);
      now.advance(const Duration(minutes: 6, seconds: 3));
      expect(exercise.elapsed, const Duration(minutes: 6, seconds: 3));
      expect(exercise.state.layout, ExerciseLayoutMode.solving);
      expect(exercise.state.speech, isNull);
      await exercise.play(move('c1c4'));
      // Acerto limpo: o tabuleiro fica onde estava; a explicação só a pedido.
      expect(exercise.state.cleanSolve, isTrue);
      expect(exercise.state.layout, ExerciseLayoutMode.solving);
      exercise.showExplanation();
      expect(exercise.state.layout, ExerciseLayoutMode.explaining);
    },
  );

  test(
    'T60: fechar no meio e voltar, o cronômetro continua de onde estava',
    () async {
      final first = cubit();
      await first.load('rook.lucena', 'e01', 'en');
      now.advance(const Duration(minutes: 1));
      await first.play(move('a1a2'));
      await first.close();
      now.advance(const Duration(seconds: 30));
      final again = cubit();
      await again.load('rook.lucena', 'e01', 'en');
      expect(again.elapsed, const Duration(minutes: 1, seconds: 30));
    },
  );

  test(
    'T60: checkpoint antigo, sem o começo, abre o cronômetro do zero',
    () async {
      progress.saved = progress.saved.withLesson(
        'rook.lucena',
        progress.saved
            .of('rook.lucena')
            .copyWith(exercise: const ExerciseCheckpoint(exerciseId: 'e01')),
      );
      final exercise = cubit();
      await exercise.load('rook.lucena', 'e01', 'en');
      expect(exercise.elapsed, Duration.zero);
      expect(
        ExerciseCheckpoint.fromJson({
          'exercise': 'e01',
          'startedAt': '2026-10-09T20:00:00.000Z',
        })!.startedAt,
        DateTime.utc(2026, 10, 9, 20),
      );
    },
  );

  test('abre com o enunciado e grava o exercício aberto', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e01', 'en');
    final state = exercise.state;
    expect(state.viktor!.name, 'Viktor');
    // O Viktor começa quieto: o objetivo fica sob o tabuleiro.
    expect(state.speech, isNull);
    expect(state.number, 1);
    expect(state.count, 3);
    expect(state.nextExercise, 'e02');
    expect(state.fen, FakeEndgameLessonRepository.lucenaFen);
    final saved = progress.saved.of('rook.lucena').exercise!;
    expect(saved.exerciseId, 'e01');
    expect(saved.open, isTrue);
  });

  test('acerto de primeira vale todas as estrelas; o Viktor fica quieto, e a '
      'solução detalhada vem a pedido', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c4'));
    final state = exercise.state;
    expect(state.phase, ExercisePhase.done);
    expect(state.earned, 3);
    expect(state.speech, isNull);
    expect(state.canExplain, isTrue);
    expect(state.locked, isFalse);
    expect(state.emotion, Emotion.happy);
    expect(progress.saved.of('rook.lucena').stars, {'e03': 3});
    expect(progress.saved.of('rook.lucena').exercise, isNull);
    // Os outros ainda estão por resolver: o próximo é o primeiro deles.
    expect(state.nextExercise, 'e01');

    exercise.showExplanation();
    expect(exercise.state.speech, 'Same bridge.');
    expect(exercise.state.explained, isTrue);
    expect(exercise.state.canExplain, isFalse);
  });

  test('erro e dica tiram uma estrela cada; a peça volta', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    expect(exercise.state.mistakes, 1);
    expect(exercise.state.fen, FakeEndgameLessonRepository.lucenaFen);
    // O erro mostra o lance errado e um "não é esse"; a pista fica para a
    // dica.
    expect(exercise.state.wrongMove, move('c1c2'));
    expect(exercise.state.speech, isNot('Same idea.'));
    expect(exercise.state.hint, isNull);

    await exercise.askHint();
    expect(exercise.state.hints, 1);
    expect(exercise.state.hint, move('c1c4'));
    expect(exercise.state.wrongMove, isNull);
    expect(exercise.state.speech, 'The hard one. Same idea.');
    // A mesma dica de novo não custa outra estrela.
    await exercise.askHint();
    expect(exercise.state.hints, 1);

    await exercise.play(move('c1c4'));
    expect(exercise.state.earned, 1);
    expect(progress.saved.of('rook.lucena').stars, {'e03': 1});
  });

  test('com todos resolvidos, o exercício é treino: a nota não muda e a '
      'explicação vem sozinha com erro', () async {
    progress = FakeEndgameProgressRepository(
      const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            stars: {'e01': 1, 'e02': 2, 'e03': 1},
          ),
        },
      ),
    );
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    expect(exercise.state.locked, isTrue);
    // Nem o exercício aberto é gravado.
    expect(progress.saved.of('rook.lucena').exercise, isNull);

    await exercise.play(move('c1c2'));
    await exercise.play(move('c1c4'));
    expect(exercise.state.phase, ExercisePhase.done);
    expect(exercise.state.earned, 2);
    // Com erro, a correção vem sozinha.
    expect(exercise.state.speech, 'Same bridge.');
    expect(exercise.state.canExplain, isFalse);
    // A nota gravada continua a mesma.
    expect(progress.saved.of('rook.lucena').stars, {
      'e01': 1,
      'e02': 2,
      'e03': 1,
    });
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

  test('o lance certo faz som; o errado, que volta, não', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');

    await exercise.play(move('c1c2'));
    expect(sound.played, isEmpty);

    await exercise.play(move('c1c4'));
    expect(sound.played, [GameSound.move]);
  });
}
