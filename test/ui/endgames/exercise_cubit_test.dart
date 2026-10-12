import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
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

  test('e14 resumed before final decision exposes all seven authored decisions only when done', () async {
    const id = 'pawns.distantOpposition';
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
      expect(first.state.explanationPayload, isNull);
    }
    await first.leave();
    final resumed = cubit(lessons: lessons, feedback: feedback);
    await resumed.load(id, 'e14', 'pt');
    expect(resumed.state.turn, line.length - 1);
    expect(resumed.state.explanationPayload, isNull);
    await resumed.play(move(line.last.accept.first));
    expect(resumed.state.phase, ExercisePhase.done);
    expect(resumed.state.explanationPayload, isNull);
    final finalFen = resumed.state.fen;
    final loadedReview = resumed.stream.firstWhere(
      (state) => state.explanationPayload != null,
    );
    resumed.showExplanation();
    await loadedReview.timeout(const Duration(seconds: 5));
    final payload = resumed.state.explanationPayload!;
    expect(
      payload.explanations
          .where((b) => b.kind == ExplanationKind.mainSolution)
          .length,
      7,
    );
    expect(payload.explanations.first.id, startsWith('exercise/e14.1:'));
    expect(payload.explanations.last.id, startsWith('exercise/e14.7:'));
    expect(resumed.state.fen, finalFen);
    expect(resumed.state.turn, line.length);
  });

  group('feedback congelado sob demanda', () {
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
      test(
        'e09 d2d3 silencioso, Dica exata em $language e último erro substitui anterior',
        () async {
          final exercise = cubit(lessons: lessons, feedback: feedback);
          await exercise.load(lessonId, 'e09', language);
          final fen = exercise.state.fen!;
          await exercise.play(move('d2d3'));
          expect(exercise.state.speech, isNull);
          expect(exercise.state.fen, fen);
          expect(exercise.state.mistakes, 1);
          await exercise.askHint();
          expect(
            exercise.state.speech,
            'Statement. ${exact(fen, 'd2d3', language)}',
          );
          expect(exercise.state.hint, isNull);
          expect(exercise.state.hints, 1);
          await exercise.askHint();
          expect(exercise.state.hints, 1);
          await exercise.play(move('d2d4'));
          expect(exercise.state.speech, isNull);
          await exercise.askHint();
          expect(
            exercise.state.speech,
            'Statement. ${exact(fen, 'd2d4', language)}',
          );
          expect(exercise.state.hints, 1);
        },
      );
    }

    test('acerto limpa contexto, erro posterior usa outra decisão; coldresume não revive texto', () async {
      final exercise = cubit(lessons: lessons, feedback: feedback);
      await exercise.load(lessonId, 'e09', 'en');
      await exercise.play(move('d2d3'));
      await exercise.play(move('h1g2'));
      expect(exercise.state.turn, 1);
      expect(exercise.state.speech, isNull);
      await exercise.askHint();
      expect(exercise.state.speech, 'Statement. Generic hint.');
      final fen = exercise.state.fen!;
      await exercise.play(move('g2f2'));
      expect(exercise.state.speech, isNull);
      await exercise.askHint();
      expect(exercise.state.speech, 'Statement. ${exact(fen, 'g2f2', 'en')}');
      final restored = cubit(lessons: lessons, feedback: feedback);
      await restored.load(lessonId, 'e09', 'en');
      expect(restored.state.fen, fen);
      expect(restored.state.turn, 1);
      expect(restored.state.mistakes, 2);
      expect(restored.state.speech, isNull);
      await restored.askHint();
      expect(restored.state.speech, 'Statement. Generic hint.');
    });

    test('lance ilegal não cria erro conceitual nem penalidade', () async {
      final exercise = cubit(lessons: lessons, feedback: feedback);
      await exercise.load(lessonId, 'e09', 'en');
      final fen = exercise.state.fen;
      await exercise.play(move('d2d5'));
      expect(exercise.state.fen, fen);
      expect(exercise.state.mistakes, 0);
      expect(exercise.state.wrongMove, isNull);
      await exercise.askHint();
      expect(exercise.state.speech, 'Statement. Generic hint.');
    });

    test('erro não mapeado e recarregar posição usam dica existente', () async {
      final exercise = cubit(lessons: lessons, feedback: feedback);
      await exercise.load(lessonId, 'e09', 'pt');
      await exercise.play(move('h1h2'));
      await exercise.askHint();
      expect(exercise.state.speech, 'Statement. Generic hint.');
      await exercise.play(move('d2d3'));
      await exercise.load(lessonId, 'e09', 'pt');
      await exercise.askHint();
      expect(exercise.state.speech, 'Statement. Generic hint.');
    });
  });

  test(
    'feedback pendente não aparece após acerto equivalente terminal',
    () async {
      final feedback = _DelayedFeedback();
      final exercise = cubit(feedback: feedback);
      await exercise.load('rook.lucena', 'e02', 'en');
      await exercise.play(move('c1c2'));
      final hint = exercise.askHint();
      await exercise.play(move('c1c5'));
      expect(exercise.state.phase, ExercisePhase.done);
      final solvedSpeech = exercise.state.speech;
      feedback.result.complete('Stale error feedback.');
      await hint;
      expect(exercise.state.phase, ExercisePhase.done);
      expect(exercise.state.speech, solvedSpeech);
      expect(exercise.state.speech, isNot(contains('Stale')));
      expect(exercise.state.hints, 0);
      expect(exercise.state.mistakes, 1);
    },
  );

  test(
    'dica atrasada não responde ao erro anterior na mesma posição',
    () async {
      final feedback = _DelayedFeedback();
      final exercise = cubit(feedback: feedback);
      await exercise.load('rook.lucena', 'e03', 'en');
      await exercise.play(move('c1c2'));
      final hint = exercise.askHint();
      await exercise.play(move('c1c3'));
      feedback.result.complete('Previous move feedback.');
      await hint;
      expect(exercise.state.speech, isNull);
      expect(exercise.state.wrongMove, move('c1c3'));
      expect(exercise.state.hints, 0);
    },
  );

  test('recarregar invalida ajuda pendente mesmo com a mesma FEN', () async {
    final feedback = _DelayedFeedback();
    final exercise = cubit(feedback: feedback);
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    final pending = exercise.askHint();
    await exercise.load('rook.lucena', 'e03', 'en');
    final restored = exercise.state;
    feedback.result.complete('STALE');
    await pending;
    expect(identical(exercise.state, restored), isTrue);
    expect(exercise.state.speech, isNull);
  });

  test(
    'falha na fonte opcional conserva a dica e penalidade existentes',
    () async {
      final feedback = _DelayedFeedback();
      final exercise = cubit(feedback: feedback);
      await exercise.load('rook.lucena', 'e03', 'en');
      await exercise.play(move('c1c2'));
      final hint = exercise.askHint();
      feedback.result.completeError(
        StateError('Unavailable optional feedback'),
      );
      await hint;
      expect(exercise.state.speech, 'The hard one. Same idea.');
      expect(exercise.state.hints, 1);
      expect(exercise.state.hint, isNull);
    },
  );

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
    // O erro só marca o lance; o Viktor permanece silencioso até a dica.
    expect(exercise.state.wrongMove, move('c1c2'));
    expect(exercise.state.speech, isNull);
    expect(exercise.state.hint, isNull);

    await exercise.askHint();
    expect(exercise.state.hints, 1);
    expect(exercise.state.hint, isNull);
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

  test('lance errado no meio do exercício: sem fala do Viktor', () async {
    final exercise = cubit();
    await exercise.load('rook.lucena', 'e03', 'en');
    await exercise.play(move('c1c2'));
    expect(exercise.state.mistakes, 1);
    expect(exercise.state.speech, isNull);
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
