import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/use_cases/exercise_review.dart';
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

  ExerciseCubit cubit({
    Duration replyDelay = Duration.zero,
    EndgameLessonRepository? lessons,
    ExerciseFeedbackRepository? feedback,
  }) {
    final cubit = ExerciseCubit(
      now: now,
      lessons: lessons ?? FakeEndgameLessonRepository(),
      feedback: feedback,
      progress: progress,
      characters: FakeCharacterRepository(),
      sounds: GameSounds(FakeSettingsRepository(), sound),
      replyDelay: replyDelay,
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

  test('e14: a notação do exercício traz as decisões escritas na aula, e a '
      'retomada guarda os lances jogados', () async {
    const id = 'pawns.waitingMoves';
    final parsed = AssetEndgameLessonRepository.parseLesson(
      jsonDecode(
        io.File('assets/lessons/endgames/$id.json').readAsStringSync(),
      ),
    );
    final lessons = FakeEndgameLessonRepository(
      trail: EndgameTrail(
        modules: [
          EndgameModule(id: 'pawns', lessons: [parsed]),
        ],
      ),
      texts: LessonTexts.fromJson({
        '$id.ex.e14.solution': 'Complete original solution.',
      }),
    );
    final feedback = AssetExerciseFeedbackRepository(_FileFeedbackAssets());
    final first = cubit(lessons: lessons, feedback: feedback);
    await first.load(id, 'e14', 'pt');
    final line = first.state.exercise!.step.line;
    for (final turn in line.take(line.length - 1)) {
      await first.play(move(turn.accept.first));
    }
    await first.leave();
    final resumed = cubit(lessons: lessons, feedback: feedback);
    await resumed.load(id, 'e14', 'pt');
    expect(resumed.state.turn, line.length - 1);
    expect(resumed.state.played, first.state.played);
    await resumed.stream
        .firstWhere((state) => state.explanationPayload != null)
        .timeout(const Duration(seconds: 5));
    await resumed.play(move(line.last.accept.first));
    expect(resumed.state.phase, ExercisePhase.done);
    expect(resumed.state.turn, line.length);
    final main = resumed.state.review.where((node) => node.depth == 0);
    expect(main.length, resumed.state.played.length);
    // As variantes escritas entram na notação.
    expect(resumed.state.review.any((node) => node.depth > 0), isTrue);
    // A lista para no lance-chave: o primeiro lance do aluno.
    expect(resumed.state.cursorId, main.first.id);
  });

  group('porquê do erro, escrito na aula', () {
    const lessonId = 'pawns.distantOpposition';
    late FakeEndgameLessonRepository lessons;
    late AssetExerciseFeedbackRepository feedback;
    late List<Map<String, dynamic>> rows;
    setUp(() {
      final lesson = AssetEndgameLessonRepository.parseLesson(
        jsonDecode(
          io.File('assets/lessons/endgames/$lessonId.json').readAsStringSync(),
        ),
      );
      lessons = FakeEndgameLessonRepository(
        trail: EndgameTrail(
          modules: [
            EndgameModule(id: 'pawns', lessons: [lesson]),
          ],
        ),
        texts: LessonTexts.fromJson({
          '$lessonId.ex.e09': 'Statement.',
          '$lessonId.ex.e09.hint': 'Generic hint.',
        }),
      );
      feedback = AssetExerciseFeedbackRepository(_FileFeedbackAssets());
      rows =
          (jsonDecode(
                    io.File(AssetExerciseFeedbackRepository.assetPath(lessonId))
                        .readAsStringSync(),
                  )['rows']
                  as List)
              .cast<Map<String, dynamic>>();
    });
    String exact(String fen, String uci, String language) =>
        rows.singleWhere(
              (row) =>
                  row['kind'] == 'exercise' &&
                  row['id'] == 'e09' &&
                  row['fen'] == fen &&
                  row['uci'] == uci,
            )[language]
            as String;

    for (final language in ['pt', 'en']) {
      test('e09: o erro põe o porquê no balão, a Dica usa o mesmo e o último '
          'erro substitui o anterior ($language)', () async {
        final exercise = cubit(lessons: lessons, feedback: feedback);
        await exercise.load(lessonId, 'e09', language);
        final fen = exercise.state.fen!;
        await exercise.play(move('d2d3'));
        expect(exercise.state.say, ExerciseSay.wrong);
        expect(exercise.state.fen, fen);
        expect(exercise.state.mistakes, 1);
        await exercise.explaining;
        // O texto da aula traz lances escritos: o balão não o mostra (a tela
        // diz o lance com a frase gerada).
        expect(
          ExerciseReview.hasNotation(exact(fen, 'd2d3', language)),
          isTrue,
        );
        expect(exercise.state.sayTexts, isEmpty);
        expect(exercise.state.sayMove, (fenBefore: fen, uci: 'd2d3'));
        await exercise.askHint();
        expect(exercise.state.say, ExerciseSay.hint);
        expect(exercise.state.sayTexts, ['Statement.', 'Generic hint.']);
        expect(exercise.state.hint, isNull);
        expect(exercise.state.hints, 1);
        await exercise.askHint();
        expect(exercise.state.hints, 1);
        await exercise.play(move('d2d4'));
        await exercise.explaining;
        expect(exercise.state.say, ExerciseSay.wrong);
        for (final text in exercise.state.sayTexts) {
          expect(ExerciseReview.hasNotation(text), isFalse);
        }
        expect(exercise.state.sayTexts.join(' '), isNot(contains('Statement')));
      });
    }

    test('acerto limpa o contexto; coldresume não revive o texto', () async {
      final exercise = cubit(lessons: lessons, feedback: feedback);
      await exercise.load(lessonId, 'e09', 'en');
      await exercise.play(move('d2d3'));
      await exercise.play(move('h1g2'));
      expect(exercise.state.turn, 1);
      expect(exercise.state.say, ExerciseSay.correct);
      await exercise.askHint();
      expect(exercise.state.sayTexts, ['Statement.', 'Generic hint.']);
      final fen = exercise.state.fen!;
      await exercise.play(move('g2f2'));
      await exercise.explaining;
      expect(exercise.state.sayTexts, isEmpty);
      expect(exercise.state.sayMove, (fenBefore: fen, uci: 'g2f2'));
      final restored = cubit(lessons: lessons, feedback: feedback);
      await restored.load(lessonId, 'e09', 'en');
      expect(restored.state.fen, fen);
      expect(restored.state.turn, 1);
      expect(restored.state.mistakes, 2);
      expect(restored.state.say, ExerciseSay.goal);
      await restored.askHint();
      expect(restored.state.sayTexts, ['Statement.', 'Generic hint.']);
    });

    test('lance ilegal não cria erro nem penalidade', () async {
      final exercise = cubit(lessons: lessons, feedback: feedback);
      await exercise.load(lessonId, 'e09', 'en');
      final fen = exercise.state.fen;
      await exercise.play(move('d2d5'));
      expect(exercise.state.fen, fen);
      expect(exercise.state.mistakes, 0);
      expect(exercise.state.wrongMove, isNull);
      expect(exercise.state.say, ExerciseSay.goal);
    });

    test('erro não mapeado usa a Dica existente', () async {
      final exercise = cubit(lessons: lessons, feedback: feedback);
      await exercise.load(lessonId, 'e09', 'pt');
      await exercise.play(move('h1h2'));
      await exercise.explaining;
      expect(exercise.state.say, ExerciseSay.wrong);
      expect(exercise.state.sayTexts, isEmpty);
      await exercise.askHint();
      expect(exercise.state.sayTexts, ['Statement.', 'Generic hint.']);
    });
  });

  test('a explicação atrasada não aparece depois do acerto', () async {
    final feedback = _DelayedFeedback();
    final exercise = cubit(feedback: feedback);
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c2'));
    final hint = exercise.askHint();
    await exercise.play(move('c1c5'));
    expect(exercise.state.phase, ExercisePhase.done);
    final solved = exercise.state.sayTexts;
    feedback.result.complete('Stale error feedback.');
    await hint;
    await exercise.explaining;
    expect(exercise.state.phase, ExercisePhase.done);
    expect(exercise.state.say, ExerciseSay.solved);
    expect(exercise.state.sayTexts, solved);
    expect(exercise.state.sayTexts, isNot(contains('Stale error feedback.')));
    expect(exercise.state.hints, 0);
    expect(exercise.state.mistakes, 1);
  });

  test('a dica atrasada não responde ao erro anterior', () async {
    final feedback = _DelayedFeedback();
    final exercise = cubit(feedback: feedback);
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    final hint = exercise.askHint();
    await exercise.play(move('c1c3'));
    feedback.result.complete('Previous move feedback.');
    await hint;
    expect(exercise.state.wrongMove, move('c1c3'));
    expect(exercise.state.hints, 0);
    expect(exercise.state.say, ExerciseSay.wrong);
  });

  test('recarregar invalida a ajuda pendente mesmo com a mesma FEN', () async {
    final feedback = _DelayedFeedback();
    final exercise = cubit(feedback: feedback);
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    final pending = exercise.askHint();
    await exercise.load('rook.lucena', 'e03', 'en');
    final restored = exercise.state;
    feedback.result.complete('STALE');
    await pending;
    await exercise.explaining;
    expect(identical(exercise.state, restored), isTrue);
  });

  test('falha na fonte opcional conserva a dica e a penalidade', () async {
    final feedback = _DelayedFeedback();
    final exercise = cubit(feedback: feedback);
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    final hint = exercise.askHint();
    feedback.result.completeError(StateError('Unavailable optional feedback'));
    await hint;
    expect(exercise.state.sayTexts, ['The hard one.', 'Same idea.']);
    expect(exercise.state.hints, 1);
    expect(exercise.state.hint, isNull);
  });

  test('T65: fechar durante resposta preserva FEN e retoma vez', () async {
    final first = cubit(replyDelay: const Duration(milliseconds: 10));
    await first.load('rook.lucena', 'e02', 'en');
    final playing = first.play(move('c1c4'));
    await Future<void>.delayed(Duration.zero);
    expect(first.state.phase, ExercisePhase.waiting);
    final waitingFen = first.state.fen;
    await first.pauseForBackground();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(first.state.fen, waitingFen);
    await first.close();
    await playing;
    final restored = cubit(replyDelay: const Duration(milliseconds: 10));
    await restored.load('rook.lucena', 'e02', 'en');
    expect(restored.state.phase, ExercisePhase.waiting);
    expect(restored.state.fen, waitingFen);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(restored.state.turn, 1);
    expect(restored.state.phase, ExercisePhase.active);
    expect(restored.state.lastMove?.uci, 'a2a1');
  });

  test(
    'T65: pausa repetida, retoma e restaura checkpoint sem contar fundo',
    () async {
      final exercise = cubit();
      await exercise.load('rook.lucena', 'e01', 'en');
      now.advance(const Duration(seconds: 12));
      await exercise.pauseForBackground();
      final checkpoint = progress.saved.of('rook.lucena').exercise!;
      expect(ExerciseCheckpoint.fromJson(checkpoint.toJson()), checkpoint);
      now.advance(const Duration(minutes: 2));
      await exercise.pauseForBackground();
      expect(exercise.elapsed, const Duration(seconds: 12));
      await exercise.resumeFromBackground();
      expect(exercise.elapsed, const Duration(seconds: 12));
      now.advance(const Duration(seconds: 3));
      await exercise.pauseForBackground();
      await exercise.close();
      now.advance(const Duration(hours: 1));
      final restored = cubit();
      await restored.load('rook.lucena', 'e01', 'en');
      expect(restored.elapsed, const Duration(seconds: 15));
      expect(restored.state.fen, exercise.state.fen);
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

  test('T60: o cronômetro conta sem limite, e a explicação não troca o '
      'tabuleiro', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    expect(exercise.elapsed, Duration.zero);
    now.advance(const Duration(minutes: 6, seconds: 3));
    expect(exercise.elapsed, const Duration(minutes: 6, seconds: 3));
    await exercise.play(move('c1c4'));
    expect(exercise.state.phase, ExercisePhase.done);
  });

  test('abre com o enunciado no balão e grava o exercício aberto', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e01', 'en');
    final state = exercise.state;
    expect(state.viktor!.name, 'Viktor');
    expect(state.say, ExerciseSay.goal);
    expect(state.sayTexts, ['White to play and win.']);
    expect(state.number, 1);
    expect(state.count, 3);
    expect(state.nextExercise, 'e02');
    expect(state.fen, FakeEndgameLessonRepository.lucenaFen);
    expect(state.worth, 1);
    final saved = progress.saved.of('rook.lucena').exercise!;
    expect(saved.exerciseId, 'e01');
    expect(saved.open, isTrue);
  });

  test('acerto de primeira vale tudo; o balão diz a solução e a notação '
      'fica completa com o último lance', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c4'));
    final state = exercise.state;
    expect(state.phase, ExercisePhase.done);
    expect(state.earned, 3);
    expect(state.say, ExerciseSay.solved);
    expect(state.sayZeroed, isFalse);
    // A solução escrita (com lances) não vai ao balão: sem comentário do
    // lance, a tela diz a frase gerada.
    expect(state.sayTexts, isEmpty);
    expect(state.sayNode?.id, state.cursorId);
    expect(state.solutionShown, isFalse);
    expect(state.locked, isFalse);
    expect(state.emotion, Emotion.happy);
    expect(state.played, ['c1c4']);
    expect(state.review.single.san, 'Rc4');
    expect(state.cursorId, state.review.single.id);
    expect(state.seen, {state.review.single.id});
    expect(progress.saved.of('rook.lucena').stars, {'e03': 3});
    expect(progress.saved.of('rook.lucena').exercise, isNull);
    // Os outros ainda estão por resolver: o próximo é o primeiro deles.
    expect(state.nextExercise, 'e01');
  });

  test('errar o primeiro lance zera: o exercício não pontua mais, mesmo '
      'resolvido depois', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    expect(exercise.state.worth, 3);
    await exercise.play(move('c1c2'));
    var state = exercise.state;
    expect(state.mistakes, 1);
    expect(state.firstMoveMistake, isTrue);
    expect(state.worth, 0);
    expect(state.zeroed, isTrue);
    expect(state.say, ExerciseSay.wrong);
    expect(state.sayZeroed, isTrue);
    // O lance volta e não entra na lista.
    expect(state.fen, FakeEndgameLessonRepository.lucenaFen);
    expect(state.played, isEmpty);
    expect(state.wrongMove, move('c1c2'));
    // Um segundo erro não repete o aviso.
    await exercise.play(move('c1c3'));
    expect(exercise.state.sayZeroed, isFalse);
    await exercise.play(move('c1c4'));
    state = exercise.state;
    expect(state.phase, ExercisePhase.done);
    expect(state.earned, 0);
    expect(state.zeroed, isTrue);
    expect(state.say, ExerciseSay.solved);
    expect(state.sayZeroed, isTrue);
    // Conta como feito, com 0 pontos.
    expect(progress.saved.of('rook.lucena').stars, {'e03': 0});
  });

  test('erro depois do primeiro lance tira um ponto, sem zerar tudo', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c4'));
    expect(exercise.state.say, ExerciseSay.correct);
    await exercise.play(move('c4c3'));
    final state = exercise.state;
    expect(state.mistakes, 1);
    expect(state.firstMoveMistake, isFalse);
    expect(state.worth, 1);
    expect(state.zeroed, isFalse);
    expect(state.wrongs.single.turn, 1);
    expect(state.played, ['c1c4', 'a2a1']);
    await exercise.play(move('c4c5'));
    expect(exercise.state.earned, 1);
    expect(progress.saved.of('rook.lucena').stars, {'e02': 1});
  });

  test('erro e dica tiram um ponto cada; a peça volta', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    expect(exercise.state.mistakes, 1);
    expect(exercise.state.fen, FakeEndgameLessonRepository.lucenaFen);
    expect(exercise.state.wrongMove, move('c1c2'));
    expect(exercise.state.hint, isNull);

    await exercise.askHint();
    expect(exercise.state.hints, 1);
    expect(exercise.state.hint, isNull);
    expect(exercise.state.wrongMove, isNull);
    expect(exercise.state.sayTexts, ['The hard one.', 'Same idea.']);
    // A mesma dica de novo não custa outro ponto.
    await exercise.askHint();
    expect(exercise.state.hints, 1);
  });

  test(
    'o lance certo no meio da linha diz "Correto." e a vez avança',
    () async {
      final exercise = cubit();
      await exercise.load('rook.lucena', 'e02', 'en');
      await exercise.play(move('c1c4'));
      expect(exercise.state.say, ExerciseSay.correct);
      expect(exercise.state.turn, 1);
      expect(exercise.state.lastMove, move('a2a1'));
      expect(exercise.state.phase, ExercisePhase.active);
      expect(exercise.state.played, ['c1c4', 'a2a1']);
      await exercise.play(move('c4c5'));
      expect(exercise.state.phase, ExercisePhase.done);
      expect(exercise.state.earned, 2);
      expect(exercise.state.played, ['c1c4', 'a2a1', 'c4c5']);
    },
  );

  test('Ver solução: joga a linha até o fim, vale 0 e a notação traz as '
      'alternativas e os erros', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c2'));
    await exercise.showSolution();
    final state = exercise.state;
    expect(state.phase, ExercisePhase.done);
    expect(state.solutionShown, isTrue);
    expect(state.earned, 0);
    expect(state.zeroed, isTrue);
    expect(state.played, ['c1c4', 'a2a1', 'c4c5']);
    // A linha principal, a alternativa aceita (c1c5) e o erro do aluno.
    final main = state.review.where((node) => node.depth == 0).toList();
    expect(main.map((node) => node.san), ['Rc4', 'Ra1', 'Rc5']);
    expect(main.first.symbol, '!');
    expect(main.last.id, state.cursorId);
    final side = state.review.where((node) => node.depth == 1).toList();
    expect(side.map((node) => node.uci), containsAll(['c1c5', 'c1c2']));
    expect(side.firstWhere((node) => node.uci == 'c1c5').symbol, '!');
    expect(side.firstWhere((node) => node.uci == 'c1c2').symbol, '?');
    expect(side.where((node) => node.startsVariant).length, 1);
    // Depois de Ver solução, o tabuleiro vai à posição final.
    expect(state.say, ExerciseSay.node);
    expect(state.sayTexts, isEmpty);
    expect(progress.saved.of('rook.lucena').stars, {'e02': 0});
    expect(progress.saved.of('rook.lucena').exercise, isNull);
    // Depois de terminar, não joga mais.
    await exercise.play(move('c5c6'));
    expect(exercise.state.played.length, 3);
  });

  test('Ver solução no meio da linha completa só o que falta', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c4'));
    await exercise.showSolution();
    expect(exercise.state.played, ['c1c4', 'a2a1', 'c4c5']);
    expect(exercise.state.earned, 0);
  });

  test('tocar num lance da notação leva o tabuleiro a ele e o balão '
      'comenta', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.showSolution();
    final review = exercise.state.review;
    final first = review.firstWhere((node) => node.uci == 'c1c4');
    final alt = review.firstWhere((node) => node.uci == 'c1c5');
    exercise.goToReview(alt.id);
    var state = exercise.state;
    expect(state.fen, alt.fenAfter);
    expect(state.lastMove, move('c1c5'));
    expect(state.cursorId, alt.id);
    expect(state.say, ExerciseSay.node);
    expect(state.sayNode?.id, alt.id);
    expect(state.browsed, 1);
    exercise.goToReview(first.id);
    expect(exercise.state.fen, first.fenAfter);
    expect(exercise.state.seen, containsAll([alt.id, first.id]));
  });

  test('resolvido jogando: os lances do aluno e a resposta contam como vistos, '
      'as variantes não', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c4'));
    await exercise.play(move('c4c5'));
    final review = exercise.state.review;
    final main = review.where((node) => node.depth == 0).map((n) => n.id);
    expect(exercise.state.seen, containsAll(main));
    for (final node in review.where((node) => node.depth > 0)) {
      expect(exercise.state.seen, isNot(contains(node.id)));
    }
  });

  test('borrar: revela UM lance por vez, o primeiro ainda não visto', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.showSolution();
    final main = exercise.state.review
        .where((node) => node.depth == 0)
        .toList();
    // O atual (o último) é o único visto.
    expect(exercise.state.seen, {main.last.id});
    // Tocar no segundo, coberto, revela o primeiro que ainda não foi visto
    // do caminho até ele: o primeiro lance.
    exercise.goToReview(main[1].id, hide: true);
    expect(exercise.state.cursorId, main[0].id);
    expect(exercise.state.seen, {main.last.id, main[0].id});
    // Tocar de novo revela o segundo.
    exercise.goToReview(main[1].id, hide: true);
    expect(exercise.state.cursorId, main[1].id);
    expect(exercise.state.seen, hasLength(3));
  });

  test('com todos resolvidos, o exercício é treino: a nota não muda', () async {
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
    expect(exercise.state.earned, 0);
    expect(exercise.state.say, ExerciseSay.solved);
    expect(exercise.state.sayZeroed, isTrue);
    expect(progress.saved.of('rook.lucena').stars, {
      'e01': 1,
      'e02': 2,
      'e03': 1,
    });
  });

  test('outro lance bom que não o ensinado resolve o exercício ali', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e02', 'en');
    await exercise.play(move('c1c5'));
    final state = exercise.state;
    expect(state.phase, ExercisePhase.done);
    expect(state.lastMove, move('c1c5'));
    expect(state.earned, 2);
    expect(state.played, ['c1c5']);
    expect(progress.saved.of('rook.lucena').stars, {'e02': 2});
    // O lance ensinado entra na notação como alternativa.
    expect(state.review.map((node) => node.uci), containsAll(['c1c5', 'c1c4']));
  });

  test('fechar no meio volta no mesmo exercício, com os erros e os lances '
      'jogados', () async {
    final first = cubit();
    await first.load('rook.lucena', 'e02', 'en');
    await first.play(move('c1c2'));
    await first.play(move('c1c4'));

    final reopened = cubit();
    await reopened.load('rook.lucena', 'e02', 'en');
    expect(reopened.state.turn, 1);
    expect(reopened.state.mistakes, 1);
    expect(reopened.state.fen, first.state.fen);
    expect(reopened.state.played, ['c1c4', 'a2a1']);
    expect(reopened.state.firstMoveMistake, isTrue);
    expect(reopened.state.zeroed, isTrue);
    expect(reopened.state.wrongs.map((w) => '${w.turn}:${w.uci}'), ['0:c1c2']);
    final saved = progress.saved.of('rook.lucena').exercise!;
    expect(saved.played, ['c1c4', 'a2a1']);
    expect(saved.wrongs, ['0:c1c2']);
    expect(saved.firstMoveMistake, isTrue);
    expect(ExerciseCheckpoint.fromJson(saved.toJson()), saved);
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

class _FileFeedbackAssets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

class _DelayedFeedback implements ExerciseFeedbackRepository {
  final result = Completer<String?>();
  @override
  Future<String?> find({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String uci,
    required String language,
  }) => result.future;
}
