import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  late FakeSchoolProgressRepository progress;
  late FakeOpponentRepository opponent;

  LessonCubit cubit({Course? course}) {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(course: course),
      progress: progress,
      characters: FakeCharacterRepository(),
      opponent: opponent,
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Move move(String uci) => Move.parse(uci)!;

  setUp(() {
    progress = FakeSchoolProgressRepository();
    opponent = FakeOpponentRepository();
  });

  test('abre no primeiro passo, com o Viktor falando', () async {
    final lesson = cubit();
    await lesson.load('pieces.rook', 'en');

    final state = lesson.state;
    expect(state.viktor!.name, 'Viktor');
    expect(state.current, isA<TalkStep>());
    expect(state.speech, 'The rook moves in straight lines.');
    expect(state.progress, 0);
    expect(state.lessonNumber, 1);
    expect(state.lessonCount, 3);
    expect(progress.saved.ongoing!.lessonId, 'pieces.rook');
  });

  test('estrelas: pega todas, conclui a aula e libera a próxima', () async {
    final lesson = cubit();
    await lesson.load('pieces.rook', 'en');
    await lesson.next();
    expect(lesson.state.current, isA<StarsStep>());
    expect(lesson.state.stars, ['a5', 'e5']);

    await lesson.play(move('a1a5'));
    expect(lesson.state.collected, ['a5']);
    expect(lesson.state.speech, 'A star!');
    expect(lesson.state.phase, StepPhase.active);

    // Um lance que a torre não faz é ignorado.
    await lesson.play(move('a5b7'));
    expect(lesson.state.fen!.startsWith('8/8/8/R7'), isTrue);

    await lesson.play(move('a5e5'));
    expect(lesson.state.phase, StepPhase.done);
    expect(lesson.state.speech, 'Well done!');
    expect(lesson.state.emotion, Emotion.happy);
    expect(lesson.state.progress, 1);

    await lesson.next();
    expect(lesson.state.finished, isTrue);
    expect(lesson.state.nextLesson, 'pieces.mate');
    expect(lesson.state.courseFinished, isFalse);
    expect(progress.saved.completed, {'pieces.rook'});
    expect(progress.saved.ongoing, isNull);
    expect(progress.saved.isStudent, isTrue);
  });

  test('lance errado: a dica, e no segundo erro a seta', () async {
    final lesson = cubit();
    await lesson.load('pieces.mate', 'en');

    await lesson.play(move('a1a7'));
    expect(lesson.state.mistakes, 1);
    expect(lesson.state.speech, 'The back rank is weak.');
    expect(lesson.state.hint, isNull);
    expect(lesson.state.fen, '6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1');

    await lesson.play(move('a1a6'));
    expect(lesson.state.hint, move('a1a8'));

    await lesson.play(move('a1a8'));
    expect(lesson.state.phase, StepPhase.done);
    expect(lesson.state.speech, 'Excellent.');
  });

  test('jogar: o mate cumpre o passo', () async {
    final lesson = cubit();
    await lesson.load('mates.queen', 'en');
    expect(lesson.state.current, isA<PlayStep>());
    await lesson.play(move('h1h8'));
    expect(lesson.state.result, PlayResult.success);
    expect(lesson.state.phase, StepPhase.done);
  });

  test('jogar: a máquina responde e a dica vira seta', () async {
    final lesson = cubit();
    await lesson.load('mates.queen', 'en');
    await lesson.play(move('h1h2'));
    expect(opponent.requests, hasLength(1));
    expect(lesson.state.moves, hasLength(2));
    expect(lesson.state.phase, StepPhase.active);

    await lesson.askHint();
    expect(lesson.state.hint, isNotNull);
    expect(lesson.state.speech, 'Look at this move.');
  });

  test(
    'afogamento: o Viktor explica e tentar de novo volta ao começo',
    () async {
      const fen = 'k7/2K5/8/8/8/8/8/1Q6 w - - 0 1';
      final lesson = cubit(
        course: const Course(
          modules: [
            CourseModule(
              id: 'mates',
              lessons: [
                Lesson(
                  id: 'mates.queen',
                  steps: [PlayStep(id: 'play', fen: fen)],
                ),
              ],
            ),
          ],
        ),
      );
      await lesson.load('mates.queen', 'en');
      await lesson.play(move('b1b6'));
      expect(lesson.state.result, PlayResult.stalemate);
      expect(lesson.state.phase, StepPhase.failed);
      expect(lesson.state.speech, 'Stalemate!');
      expect(lesson.state.emotion, Emotion.surprised);

      await lesson.retry();
      expect(lesson.state.fen, fen);
      expect(lesson.state.moves, isEmpty);
      expect(lesson.state.phase, StepPhase.active);
      expect(lesson.state.result, isNull);
    },
  );

  test('fechar no meio volta no mesmo passo e com o mesmo tabuleiro', () async {
    final first = cubit();
    await first.load('pieces.rook', 'en');
    await first.next();
    await first.play(move('a1a5'));
    expect(progress.saved.ongoing!.open, isTrue);

    final reopened = cubit();
    await reopened.load('pieces.rook', 'en');
    expect(reopened.state.step, 1);
    expect(reopened.state.collected, ['a5']);
    expect(reopened.state.fen, first.state.fen);
  });

  test(
    'sair pelo voltar guarda o passo, mas o app não reabre na aula',
    () async {
      final lesson = cubit();
      await lesson.load('pieces.rook', 'en');
      await lesson.next();
      await lesson.leave();
      expect(progress.saved.ongoing!.step, 1);
      expect(progress.saved.ongoing!.open, isFalse);
    },
  );

  test('a última aula do curso é a formatura', () async {
    progress.saved = const SchoolProgress(
      completed: {'pieces.rook', 'pieces.mate'},
    );
    final lesson = cubit();
    await lesson.load('mates.queen', 'en');
    await lesson.play(move('h1h8'));
    await lesson.next();
    expect(lesson.state.courseFinished, isTrue);
    expect(lesson.state.speech, 'You graduated.');
  });

  test('aula que não existe', () async {
    final lesson = cubit();
    await lesson.load('nothing', 'en');
    expect(lesson.state.missing, isTrue);
  });

  group('lição de uma aula de final', () {
    late FakeEndgameProgressRepository endgames;

    LessonCubit endgameCubit() {
      final cubit = LessonCubit(
        source: EndgameLessonSource(FakeEndgameLessonRepository(), endgames),
        characters: FakeCharacterRepository(),
        opponent: opponent,
        replyDelay: Duration.zero,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    setUp(() => endgames = FakeEndgameProgressRepository());

    test('abre a lição da aula com as falas dela', () async {
      final lesson = endgameCubit();
      await lesson.load('rook.lucena', 'en');
      expect(lesson.state.endgame, isTrue);
      expect(lesson.state.speech, 'This is the Lucena position.');
      expect(lesson.state.lessonNumber, 1);
      expect(lesson.state.lessonCount, 2);
      expect(endgames.saved.ongoing!.lessonId, 'rook.lucena');
    });

    test('concluir marca a lição feita, sem formatura', () async {
      final lesson = endgameCubit();
      await lesson.load('rook.lucena', 'en');
      await lesson.next();
      await lesson.play(move('c1c4'));
      expect(lesson.state.speech, 'That is the bridge.');
      await lesson.next();
      expect(lesson.state.finished, isTrue);
      expect(lesson.state.courseFinished, isFalse);
      expect(lesson.state.nextLesson, 'rook.philidor');
      expect(endgames.saved.of('rook.lucena').lessonDone, isTrue);
      expect(endgames.saved.ongoing, isNull);
    });

    test('a última lição da trilha também não é formatura', () async {
      final lesson = endgameCubit();
      await lesson.load('rook.philidor', 'en');
      await lesson.next();
      expect(lesson.state.finished, isTrue);
      expect(lesson.state.courseFinished, isFalse);
      expect(lesson.state.nextLesson, isNull);
    });

    test('fechar no meio volta no mesmo passo', () async {
      final first = endgameCubit();
      await first.load('rook.lucena', 'en');
      await first.next();
      final reopened = endgameCubit();
      await reopened.load('rook.lucena', 'en');
      expect(reopened.state.step, 1);
      expect(reopened.state.current, isA<MoveStep>());
    });

    test('sair pelo voltar guarda o passo fechado', () async {
      final lesson = endgameCubit();
      await lesson.load('rook.lucena', 'en');
      await lesson.leave();
      expect(endgames.saved.ongoing!.open, isFalse);
      expect(endgames.saved.lessons, isEmpty);
    });
  });
}
