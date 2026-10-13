import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository.dart';
import 'package:lucena/data/repositories/endgames/exercise_feedback_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/explanation.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import 'package:lucena/data/repositories/school/lesson_source.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

import 'package:lucena/domain/models/game_sound.dart';
import 'package:lucena/ui/core/sound/game_sounds.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_sound_repository.dart';

void main() {
  late FakeSchoolProgressRepository progress;
  late FakeOpponentRepository opponent;
  late FakeSoundRepository sound;

  LessonCubit cubit({
    Course? course,
    LessonTexts? texts,
    ExerciseFeedbackRepository? feedback,
  }) {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(course: course, texts: texts),
      feedback: feedback,
      progress: progress,
      characters: FakeCharacterRepository(),
      opponent: opponent,
      sounds: GameSounds(FakeSettingsRepository(), sound),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Move move(String uci) => Move.parse(uci)!;

  setUp(() {
    progress = FakeSchoolProgressRepository();
    opponent = FakeOpponentRepository();
    sound = FakeSoundRepository();
  });

  group('feedback contextual da lição', () {
    const id = 'pawns.distantOpposition';
    late MoveStep step;
    late Course course;
    late List<Map<String, dynamic>> rows;
    setUp(() {
      final lesson = AssetEndgameLessonRepository.parseLesson(
        jsonDecode(
          io.File('assets/lessons/endgames/$id.json').readAsStringSync(),
        ),
      ).lesson;
      step = lesson.steps.whereType<MoveStep>().singleWhere(
        (s) => s.id == 'convert',
      );
      course = Course(
        modules: [
          CourseModule(
            id: 'pawns',
            lessons: [
              Lesson(
                id: id,
                steps: [
                  const TalkStep(id: 'intro'),
                  step,
                ],
              ),
            ],
          ),
        ],
      );
      rows =
          (jsonDecode(
                    io.File(AssetExerciseFeedbackRepository.assetPath(id))
                        .readAsStringSync(),
                  )['rows']
                  as List)
              .cast<Map<String, dynamic>>();
    });
    for (final language in ['pt', 'en']) {
      test('tipo move, turn 1-based e FEN completa em $language', () async {
        final lesson = cubit(
          course: course,
          feedback: AssetExerciseFeedbackRepository(
            _FeedbackAssets(legacyOnly: true),
          ),
        );
        await lesson.load(id, language);
        await lesson.next();
        for (var turn = 0; turn < step.line.length; turn++) {
          final fen = lesson.state.fen;
          final errors = rows
              .where(
                (r) =>
                    r['kind'] == 'move' &&
                    r['id'] == step.id &&
                    r['turn'] == turn + 1 &&
                    r['fen'] == fen,
              )
              .take(2);
          expect(errors, isNotEmpty);
          for (final row in errors) {
            final mistakes = lesson.state.mistakes;
            await lesson.play(move(row['uci'] as String));
            expect(
              lesson.state.speech,
              row[language],
              reason:
                  'turn=$turn uci=${row["uci"]} phase=${lesson.state.phase} payload=${lesson.state.explanation?.explanations.map((b) => b.kind.name).toList()}',
            );
            expect(lesson.state.mistakes, mistakes + 1);
            expect(lesson.state.turn, turn);
            expect(lesson.state.fen, fen);
          }
          await lesson.play(move(step.line[turn].accept.first));
          expect(lesson.state.speech, isNot(errors.last[language]));
        }
        expect(lesson.state.phase, StepPhase.done);
      });
    }
    for (final action in ['correct', 'reload', 'back', 'new error']) {
      test('resposta atrasada invalidada por $action', () async {
        final feedback = _PendingLessonFeedback();
        final lesson = cubit(course: course, feedback: feedback);
        await lesson.load(id, 'en');
        await lesson.next();
        final pending = lesson.play(move('d3e3'));
        expect(lesson.state.mistakes, 1);
        Future<void>? newer;
        switch (action) {
          case 'correct':
            await lesson.play(move(step.line.first.accept.first));
          case 'reload':
            await lesson.load(id, 'en');
          case 'back':
            await lesson.back();
          case 'new error':
            newer = lesson.play(move('g3g4'));
        }
        final speech = lesson.state.speech;
        feedback.results.first.complete('STALE');
        await pending;
        expect(lesson.state.speech, speech);
        if (newer != null) {
          feedback.results.last.complete('Latest error');
          await newer;
          expect(lesson.state.speech, 'Latest error');
        }
      });
    }
    test('falha opcional mantém feedback habitual, sem avançar', () async {
      final feedback = _PendingLessonFeedback();
      final lesson = cubit(
        course: course,
        feedback: feedback,
        texts: LessonTexts.fromJson({'$id.convert.hint': 'Generic hint.'}),
      );
      await lesson.load(id, 'en');
      await lesson.next();
      final pending = lesson.play(move('d3e3'));
      feedback.results.single.completeError(StateError('Unavailable'));
      await pending;
      expect(lesson.state.speech, 'Generic hint.');
      expect(lesson.state.turn, 0);
      expect(lesson.state.mistakes, 1);
      expect(lesson.state.fen, step.fen);
    });

    test('movimento ilegal não consulta feedback nem conta erro', () async {
      final feedback = _PendingLessonFeedback();
      final lesson = cubit(course: course, feedback: feedback);
      await lesson.load(id, 'en');
      await lesson.next();
      await lesson.play(move('d3d6'));
      expect(lesson.state.mistakes, 0);
      expect(feedback.results, isEmpty);
    });
  });

  test(
    'real demo captions follow zero, first, next, back and replay',
    () async {
      const id = 'pawns.distantOpposition';
      final parsed = AssetEndgameLessonRepository.parseLesson(
        jsonDecode(
          io.File('assets/lessons/endgames/$id.json').readAsStringSync(),
        ),
      );
      final step = parsed.lesson.steps.whereType<DemoStep>().singleWhere(
        (s) => s.id == 'd_distant',
      );
      final feedback = AssetExerciseFeedbackRepository(_FeedbackAssets());
      final expected = (await feedback.findPayload(
        lessonId: id,
        exerciseId: step.id,
        kind: 'demo',
        turn: 1,
        fen: step.fen,
        language: 'pt',
        state: ExplanationState.review,
      ))!;
      final main = expected.explanations.singleWhere(
        (b) => b.kind == ExplanationKind.mainSolution,
      );
      final demo = cubit(
        course: Course(
          modules: [
            CourseModule(
              id: 'pawns',
              lessons: [
                Lesson(id: id, steps: [step]),
              ],
            ),
          ],
        ),
        feedback: feedback,
      );
      Future<void> settle() => Future<void>.delayed(Duration.zero);
      List<String> caption() => demo.state.explanation!.explanations
          .singleWhere((b) => b.kind == ExplanationKind.mainSolution)
          .texts;
      await demo.load(id, 'pt');
      await settle();
      expect(caption(), main.texts);
      for (final ply in [1, 2, 3]) {
        await demo.demoForward();
        await settle();
        expect(demo.state.demoMove, ply);
        expect(caption(), main.variations.single.explanationByPly[ply]);
      }
      await demo.demoBack();
      await settle();
      expect(caption(), main.variations.single.explanationByPly[2]);
      await demo.demoReplay();
      await settle();
      expect(demo.state.demoMove, 0);
      expect(caption(), main.texts);
      await demo.demoForward();
      await settle();
      expect(caption(), main.variations.single.explanationByPly[1]);
      expect(demo.state.mistakes, 0);
    },
  );

  test(
    'real rich move error precedes solution without moving position or turn',
    () async {
      const id = 'pawns.distantOpposition';
      final parsed = AssetEndgameLessonRepository.parseLesson(
        jsonDecode(
          io.File('assets/lessons/endgames/$id.json').readAsStringSync(),
        ),
      );
      final step = parsed.lesson.steps.whereType<MoveStep>().singleWhere(
        (s) => s.id == 'convert',
      );
      final lesson = cubit(
        course: Course(
          modules: [
            CourseModule(
              id: 'pawns',
              lessons: [
                Lesson(id: id, steps: [step]),
              ],
            ),
          ],
        ),
        feedback: AssetExerciseFeedbackRepository(_FeedbackAssets()),
      );
      await lesson.load(id, 'pt');
      await lesson.play(move('d3e3'));
      await Future<void>.delayed(Duration.zero);
      expect(
        lesson.state.explanation!.explanations.first.kind,
        ExplanationKind.playedIncorrect,
      );
      expect(
        lesson.state.explanation!.explanations.first.variations.single.firstUci,
        'd3e3',
      );
      expect(lesson.state.fen, step.fen);
      expect(lesson.state.turn, 0);
      expect(lesson.state.mistakes, 1);
    },
  );

  test(
    'real demo after think retains feedback and its own ply caption',
    () async {
      const id = 'pawns.distantOpposition';
      final parsed = AssetEndgameLessonRepository.parseLesson(
        jsonDecode(
          io.File('assets/lessons/endgames/$id.json').readAsStringSync(),
        ),
      );
      final steps = parsed.lesson.steps;
      final index = steps.indexWhere((s) => s.id == 'd_distant');
      final think = steps.whereType<ThinkStep>().singleWhere(
        (s) => s.id == 't_lesson',
      );
      final demo = steps[index] as DemoStep;
      final feedback = AssetExerciseFeedbackRepository(_FeedbackAssets());
      final expected = (await feedback.findPayload(
        lessonId: id,
        exerciseId: demo.id,
        kind: 'demo',
        turn: 1,
        fen: demo.fen,
        language: 'pt',
        state: ExplanationState.review,
      ))!;
      final caption = expected.explanations
          .singleWhere((b) => b.kind == ExplanationKind.mainSolution)
          .variations
          .single
          .explanationByPly;
      final lesson = cubit(
        course: Course(
          modules: [
            CourseModule(
              id: 'pawns',
              lessons: [
                Lesson(id: id, steps: [think, demo]),
              ],
            ),
          ],
        ),
        feedback: feedback,
      );
      await lesson.load(id, 'pt');
      await lesson.play(move(demo.line.first.uci));
      await Future<void>.delayed(Duration.zero);
      expect(lesson.state.current, isA<DemoStep>());
      expect(lesson.state.explanation!.positionId, expected.positionId);
      expect(
        lesson.state.explanation!.explanations.first.kind,
        ExplanationKind.playedCorrect,
      );
      expect(
        lesson.state.explanation!.explanations
            .singleWhere((b) => b.kind == ExplanationKind.mainSolution)
            .texts,
        caption[1],
      );
      await lesson.demoForward();
      await Future<void>.delayed(Duration.zero);
      expect(
        lesson.state.explanation!.explanations.any(
          (b) => b.kind == ExplanationKind.playedCorrect,
        ),
        isFalse,
      );
      expect(
        lesson.state.explanation!.explanations
            .singleWhere((b) => b.kind == ExplanationKind.mainSolution)
            .texts,
        caption[2],
      );
    },
  );

  for (final stepId in ['edgeMove', 'protectPawnMove']) {
    test('active move context follows replies in $stepId', () async {
      const id = 'pawns.distantOpposition';
      final parsed = AssetEndgameLessonRepository.parseLesson(
        jsonDecode(
          io.File('assets/lessons/endgames/$id.json').readAsStringSync(),
        ),
      );
      final step = parsed.lesson.steps.whereType<MoveStep>().singleWhere(
        (step) => step.id == stepId,
      );
      final feedback = AssetExerciseFeedbackRepository(_FeedbackAssets());
      final lesson = cubit(
        course: Course(
          modules: [
            CourseModule(
              id: 'pawns',
              lessons: [
                Lesson(id: id, steps: [step]),
              ],
            ),
          ],
        ),
        feedback: feedback,
      );
      await lesson.load(id, 'pt');
      for (final turn in step.line) {
        final originFen = lesson.state.fen!;
        final originTurn = lesson.state.turn + 1;
        final uci = turn.accept.first;
        await lesson.play(move(uci));
        final done = lesson.state.phase == StepPhase.done;
        final expected = await feedback.findPayload(
          lessonId: id,
          exerciseId: stepId,
          kind: 'move',
          turn: done ? originTurn : lesson.state.turn + 1,
          fen: done ? originFen : lesson.state.fen!,
          language: 'pt',
          state: done ? ExplanationState.correct : ExplanationState.intro,
          playedUci: done ? uci : null,
        );
        await Future<void>.delayed(Duration.zero);
        expect(expected, isNotNull);
        expect(lesson.state.explanation?.positionId, expected!.positionId);
        expect(lesson.state.explanation?.state, expected.state);
        expect(
          lesson.state.speech,
          expected.explanations.expand((block) => block.texts).join('\n\n'),
        );
        if (done) break;
      }
      expect(lesson.state.phase, StepPhase.done);
    });
  }

  test('late move context cannot replace the next decision context', () async {
    const id = 'pawns.distantOpposition';
    final parsed = AssetEndgameLessonRepository.parseLesson(
      jsonDecode(
        io.File('assets/lessons/endgames/$id.json').readAsStringSync(),
      ),
    );
    final step = parsed.lesson.steps.whereType<MoveStep>().singleWhere(
      (step) => step.id == 'edgeMove',
    );
    final feedback = _DelayedMoveContextFeedback();
    final lesson = cubit(
      course: Course(
        modules: [
          CourseModule(
            id: 'pawns',
            lessons: [
              Lesson(id: id, steps: [step]),
            ],
          ),
        ],
      ),
      feedback: feedback,
    );
    await lesson.load(id, 'pt');
    await lesson.play(move(step.line.first.accept.first));
    expect(feedback.delayedRequests, 1);
    expect(lesson.state.turn, 1);
    await lesson.play(move(step.line[1].accept.first));
    final expected = await feedback.delegate.findPayload(
      lessonId: id,
      exerciseId: step.id,
      kind: 'move',
      turn: 3,
      fen: lesson.state.fen!,
      language: 'pt',
      state: ExplanationState.intro,
    );
    await Future<void>.delayed(Duration.zero);
    expect(lesson.state.explanation?.positionId, expected!.positionId);
    final current = lesson.state;
    feedback.pending.complete(ExplanationPayload.context(['STALE']));
    await Future<void>.delayed(Duration.zero);
    expect(lesson.state, same(current));
  });

  test('abre no primeiro passo, com o Viktor falando', () async {
    final lesson = cubit();
    await lesson.load('pieces.rook', 'en');

    final state = lesson.state;
    expect(state.viktor!.name, 'Viktor');
    expect(state.current, isA<TalkStep>());
    expect(state.speech, 'The rook moves in straight lines.');
    expect(state.progress, 1 / state.stepCount);
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

  group('pensar: o lance do aluno', () {
    const fen = 'k7/8/8/8/4P3/8/4K3/8 w - - 0 1';
    const course = Course(
      modules: [
        CourseModule(
          id: 'pawns',
          lessons: [
            Lesson(
              id: 'pawns.keys',
              steps: [
                ThinkStep(
                  id: 'start',
                  fen: fen,
                  accept: {'e2d3', 'e2e3', 'e2f3'},
                  refusals: {'e4e5': 1},
                  mistakes: {'e2d2': StepMistake(say: 'step.start.e2d2')},
                ),
                TalkStep(id: 'explain', fen: fen),
              ],
            ),
          ],
        ),
      ],
    );
    final texts = LessonTexts.fromJson({
      'module.pawns': 'Pawns',
      'pawns.keys.title': 'Key squares',
      'pawns.keys.start': 'Find the route.',
      'pawns.keys.start.hint1': '1.e5? Kb7: Black reaches the pawn and draws.',
      'pawns.keys.start.e2d2': '1.Kd2? Kb7 gives Black the opposition.',
      'pawns.keys.explain': 'Every route reaches a key square.',
      'coach.praise': ['Correct.'],
      'coach.lessonDone': ['Lesson done.'],
    });

    Future<LessonCubit> open() async {
      final lesson = cubit(course: course, texts: texts);
      await lesson.load('pawns.keys', 'en');
      return lesson;
    }

    test('errado previsto: a explicação abre pela fala do erro', () async {
      final lesson = await open();
      await lesson.play(move('e2d2'));
      expect(lesson.state.step, 1);
      expect(lesson.state.thinkMistake, isNull);
      expect(
        lesson.state.speech,
        '1.Kd2? Kb7 gives Black the opposition.\n\n'
        'Find the route. Every route reaches a key square.',
      );
    });

    test(
      'errado fora dos dados e sem motor: a peça volta e avisa (T70)',
      () async {
        final lesson = await open();
        await lesson.play(move('e2f2'));
        expect(lesson.state.step, 0);
        expect(lesson.state.wrongNotice, isTrue);
        expect(lesson.state.fen, fen);
        expect(lesson.state.mistakes, 1);
      },
    );

    test('lance recusado (refusals) também abre a explicação', () async {
      final lesson = await open();
      await lesson.play(move('e4e5'));
      expect(lesson.state.step, 1);
      expect(lesson.state.thinkMistake, '1.e5');
    });

    test('certo: o estado correto, sem frase de acerto (T70)', () async {
      final lesson = await open();
      await lesson.play(move('e2d3'));
      expect(lesson.state.step, 1);
      expect(lesson.state.correct, isTrue);
      expect(lesson.state.thinkMistake, isNull);
      expect(lesson.state.speech, 'Every route reaches a key square.');
    });
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

    test('outro lance bom que não o ensinado cumpre o passo ali', () async {
      const fen = FakeEndgameLessonRepository.lucenaFen;
      final lessons = FakeEndgameLessonRepository(
        trail: const EndgameTrail(
          modules: [
            EndgameModule(
              id: 'rook',
              lessons: [
                EndgameLesson(
                  id: 'rook.lucena',
                  module: 'rook',
                  lesson: Lesson(
                    id: 'rook.lucena',
                    steps: [
                      MoveStep(
                        id: 'bridge',
                        fen: fen,
                        line: [
                          MoveTurn(accept: {'c1c4', 'c1c5'}, reply: 'a2a1'),
                          MoveTurn(accept: {'c4c5'}),
                        ],
                      ),
                    ],
                  ),
                  exercises: [],
                  passScore: 0,
                  keyPositions: [],
                  practice: Practice(
                    fen: fen,
                    goal: PositionGoal.win,
                    positionId: null,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      final lesson = LessonCubit(
        source: EndgameLessonSource(lessons, endgames),
        characters: FakeCharacterRepository(),
        opponent: opponent,
        replyDelay: Duration.zero,
      );
      addTearDown(lesson.close);
      await lesson.load('rook.lucena', 'en');
      await lesson.play(move('c1c5'));
      // A resposta e a vez seguinte valem só para o lance ensinado.
      expect(lesson.state.phase, StepPhase.done);
      expect(lesson.state.lastMove, move('c1c5'));
    });

    test('sair pelo voltar guarda o passo fechado', () async {
      final lesson = endgameCubit();
      await lesson.load('rook.lucena', 'en');
      await lesson.leave();
      expect(endgames.saved.ongoing!.open, isFalse);
      expect(endgames.saved.lessons, isEmpty);
    });
  });

  test(
    'no passo das estrelas, cada lance da peça faz o som de lance',
    () async {
      final lesson = cubit();
      await lesson.load('pieces.rook', 'en');
      await lesson.next();

      await lesson.play(move('a1a5'));
      expect(sound.played, [GameSound.move]);
    },
  );

  group('voltar um passo', () {
    const course = Course(
      modules: [
        CourseModule(
          id: 'pieces',
          lessons: [
            Lesson(
              id: 'pieces.rook',
              steps: [
                TalkStep(id: 'intro', fen: '8/8/8/8/3R4/8/8/8 w - - 0 1'),
                StarsStep(
                  id: 'stars',
                  fen: '8/8/8/8/8/8/8/R7 w - - 0 1',
                  stars: ['a5', 'e5'],
                ),
                TalkStep(id: 'outro', fen: '8/8/8/8/3R4/8/8/8 w - - 0 1'),
              ],
            ),
          ],
        ),
      ],
    );

    test('no primeiro passo não há voltar', () async {
      final lesson = cubit(course: course);
      await lesson.load('pieces.rook', 'en');
      expect(lesson.state.canGoBack, isFalse);
      await lesson.back();
      expect(lesson.state.step, 0);
    });

    test('volta ao passo anterior, do começo; um passo já cumprido pode ser '
        'pulado com "continuar"', () async {
      final lesson = cubit(course: course);
      await lesson.load('pieces.rook', 'en');
      await lesson.next();
      await lesson.play(move('a1a5'));
      await lesson.play(move('a5e5'));
      expect(lesson.state.phase, StepPhase.done);
      await lesson.next();
      expect(lesson.state.step, 2);

      await lesson.back();
      expect(lesson.state.step, 1);
      // O passo abre do começo: as estrelas voltam e dá para jogar de novo.
      expect(lesson.state.collected, isEmpty);
      expect(lesson.state.interactive, isTrue);
      expect(lesson.state.reviewing, isTrue);
      expect(lesson.state.canContinue, isTrue);

      await lesson.back();
      expect(lesson.state.step, 0);
      await lesson.next();
      await lesson.next();
      expect(lesson.state.step, 2);
    });

    test('um passo ainda não cumprido continua pedindo o lance', () async {
      final lesson = cubit(course: course);
      await lesson.load('pieces.rook', 'en');
      await lesson.next();
      await lesson.back();
      await lesson.next();
      expect(lesson.state.step, 1);
      expect(lesson.state.canContinue, isFalse);
    });
  });

  group('o passo de tocar na casa', () {
    const course = Course(
      modules: [
        CourseModule(
          id: 'notation',
          lessons: [
            Lesson(
              id: 'notation.coordinates',
              steps: [
                TapStep(
                  id: 'find',
                  fen: '8/8/8/8/8/8/8/8 w - - 0 1',
                  targets: ['e4', 'a1'],
                ),
              ],
            ),
          ],
        ),
      ],
    );

    test('a casa pedida, uma de cada vez; a errada não conta', () async {
      final lesson = cubit(course: course);
      await lesson.load('notation.coordinates', 'en');
      expect(lesson.state.tapTarget, 'e4');
      // Tocar não move peça nenhuma.
      expect(lesson.state.interactive, isFalse);

      await lesson.tap('d4');
      expect(lesson.state.tapTarget, 'e4');
      expect(lesson.state.phase, StepPhase.active);

      await lesson.tap('e4');
      expect(lesson.state.tapTarget, 'a1');
      // A barra anda por passo, não por casa tocada.
      expect(lesson.state.progress, 1 / lesson.state.stepCount);

      await lesson.tap('a1');
      expect(lesson.state.phase, StepPhase.done);
      expect(lesson.state.tapTarget, isNull);
    });
  });
}

class _FeedbackAssets extends AssetService {
  _FeedbackAssets({this.legacyOnly = false});
  final bool legacyOnly;
  @override
  Future<String> loadString(String path) async {
    final text = await io.File(path).readAsString();
    if (!legacyOnly) return text;
    final data = jsonDecode(text) as Map<String, dynamic>;
    data.remove('positions');
    return jsonEncode(data);
  }
}

class _PendingLessonFeedback implements ExerciseFeedbackRepository {
  final results = <Completer<String?>>[];
  @override
  Future<String?> find({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String uci,
    required String language,
  }) {
    final result = Completer<String?>();
    results.add(result);
    return result.future;
  }
}

class _DelayedMoveContextFeedback extends EmptyExerciseFeedbackRepository
    implements ExplanationRepository {
  final delegate = AssetExerciseFeedbackRepository(_FeedbackAssets());
  final pending = Completer<ExplanationPayload?>();
  int delayedRequests = 0;

  @override
  Future<ExplanationPayload?> findPayload({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String language,
    required ExplanationState state,
    String? playedUci,
  }) {
    if (kind == 'move' && turn == 2 && state == ExplanationState.intro) {
      delayedRequests++;
      return pending.future;
    }
    return delegate.findPayload(
      lessonId: lessonId,
      exerciseId: exerciseId,
      kind: kind,
      turn: turn,
      fen: fen,
      language: language,
      state: state,
      playedUci: playedUci,
    );
  }
}
