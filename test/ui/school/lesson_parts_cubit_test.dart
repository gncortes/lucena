import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';

/// T51, C3: a lição de uma aula em partes, o passo de pensar (o cronômetro
/// e as dicas, T60) e a demonstração (o professor joga).
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  final lesson = Lesson.parted(
    id: 'rook.lucena',
    parts: const [
      LessonPart(
        id: 'bridge',
        steps: [
          ThinkStep(id: 'think', fen: fen, hints: 2, arrows: [('c1', 'c4')]),
          DemoStep(
            id: 'demo',
            fen: fen,
            line: [
              DemoMove(uci: 'c1c4', arrows: [('c4', 'b4')]),
              DemoMove(uci: 'a2a1'),
            ],
          ),
          MoveStep(
            id: 'try',
            fen: fen,
            line: [
              MoveTurn(accept: {'c1c4', 'c1c5'}),
            ],
          ),
        ],
      ),
      LessonPart(
        id: 'final',
        steps: [TalkStep(id: 'end', fen: fen)],
      ),
    ],
  );
  final rawTexts = <String, Object>{
    'rook.lucena.think': 'Where should the rook go?',
    'rook.lucena.think.hint1': 'Think about a bridge.',
    'rook.lucena.think.hint2': 'The fourth rank.',
    'rook.lucena.demo': 'Watch.',
    'rook.lucena.demo.m1': 'The rook builds the bridge.',
    'rook.lucena.demo.m2': 'Black checks.',
    'coach.thinkRight': ['Correct!'],
  };
  final texts = LessonTexts.fromJson(rawTexts);
  final trail = EndgameTrail(
    modules: [
      EndgameModule(
        id: 'rook',
        lessons: [
          EndgameLesson(
            id: 'rook.lucena',
            module: 'rook',
            lesson: lesson,
            exercises: const [],
            passScore: 0,
            keyPositions: const [],
            practice: const Practice(fen: fen, goal: PositionGoal.win),
          ),
        ],
      ),
    ],
  );

  late FakeNow now;
  late FakeEndgameProgressRepository progress;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 8, 20));
    progress = FakeEndgameProgressRepository();
  });

  Future<LessonCubit> open({
    String? part,
    Map<String, Object> withTexts = const {},
  }) async {
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(
          trail: trail,
          texts: withTexts.isEmpty
              ? texts
              : LessonTexts.fromJson({...rawTexts, ...withTexts}),
        ),
        progress,
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      now: now,
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en', part: part);
    return cubit;
  }

  test(
    'T65: timer exclui fundo; fechar de verdade reabre no início da parte',
    () async {
      final cubit = await open();
      await cubit.startStepClock();
      now.advance(const Duration(seconds: 9));
      await cubit.pauseForBackground();
      final saved = progress.saved.ongoing!;
      expect(LessonCheckpoint.fromJson(saved.toJson())!.stepPausedAt, now());
      now.advance(const Duration(hours: 1));
      await cubit.pauseForBackground();
      expect(cubit.stepElapsed, const Duration(seconds: 9));
      await cubit.resumeFromBackground();
      expect(cubit.stepElapsed, const Duration(seconds: 9));
      await cubit.next();
      await cubit.demoForward();
      cubit.demoTogglePause();
      await cubit.pauseForBackground();
      now.advance(const Duration(hours: 1));
      await cubit.close();
      // Fechar de verdade reabre no início da parte (decisão de 2026-10-13).
      final restored = await open();
      expect(restored.state.current?.id, 'think');
      expect(restored.state.demoMove, 0);
      expect(restored.stepElapsed, Duration.zero);
    },
  );

  test('sair pela seta e entrar de novo, com o app aberto, recomeça a '
      'parte em que estava', () async {
    final cubit = await open(part: 'bridge');
    await cubit.next();
    expect(cubit.state.current?.id, 'demo');
    await cubit.leave();
    await cubit.close();
    // A rota cria um cubit novo a cada entrada.
    final again = await open();
    expect(again.state.part?.id, 'bridge');
    expect(again.state.step, 0);
    expect(again.state.current?.id, 'think');
  });

  test('abre a primeira parte, só com os passos dela', () async {
    final cubit = await open();
    expect(cubit.state.part?.id, 'bridge');
    expect(cubit.state.partNumber, 1);
    expect(cubit.state.partCount, 2);
    expect(cubit.state.stepCount, 3);
  });

  test('abre qualquer parte direto, sem travas', () async {
    final cubit = await open(part: 'final');
    expect(cubit.state.part?.id, 'final');
    expect(cubit.state.current?.id, 'end');
  });

  test(
    'pensar: resolvendo, com dica e "Ver explicação" desde o começo',
    () async {
      final cubit = await open();
      expect(cubit.state.layout, LessonLayoutMode.solving);
      expect(cubit.state.canHint, isTrue);
      expect(cubit.state.canContinue, isTrue);
      expect(cubit.state.arrows, isEmpty);
      expect(cubit.state.speech, 'Where should the rook go?');
    },
  );

  test(
    'pensar: o lance certo segue no tabuleiro, sem frase de acerto',
    () async {
      final cubit = await open();
      await cubit.play(Move.parse('c1c4')!);
      expect(cubit.state.current?.id, 'demo');
      // A demonstração já começa depois do lance do aluno, sem refazê-lo.
      expect(cubit.state.demoMove, 1);
      expect(cubit.state.lastMove, Move.parse('c1c4'));
      expect(cubit.state.correct, isTrue);
      expect(cubit.state.speech, isNot(startsWith('Correct!')));
    },
  );

  test('pensar: outro lance aceito chega ao mesmo estado correto', () async {
    final cubit = await open();
    await cubit.play(Move.parse('c1c5')!);
    expect(cubit.state.current?.id, 'demo');
    expect(cubit.state.demoMove, 1);
    expect(cubit.state.correct, isTrue);
  });

  test('pensar: lance fora dos dados, sem motor: a peça volta', () async {
    final cubit = await open();
    await cubit.play(Move.parse('c1c2')!);
    expect(cubit.state.current?.id, 'think');
    expect(cubit.state.wrongNotice, isTrue);
  });

  test('pensar: a explicação começa pelo contexto do enunciado, sem a '
      'pergunta', () async {
    final cubit = await open(
      withTexts: {
        'rook.lucena.think':
            'White to move. The black king is cut off. '
            'Where should the rook go?',
      },
    );
    await cubit.next();
    expect(cubit.state.current?.id, 'demo');
    expect(cubit.state.speech, 'The black king is cut off. Watch.');
  });

  test('cronômetro: zero ao abrir, cresce, e passar de 6 minutos não muda '
      'nada', () async {
    final cubit = await open();
    // O relógio só começa depois da apresentação do Viktor (§8).
    expect(cubit.state.presenting, isTrue);
    await cubit.startStepClock();
    expect(cubit.stepElapsed, Duration.zero);
    now.advance(const Duration(minutes: 6, seconds: 1));
    expect(cubit.stepElapsed, const Duration(minutes: 6, seconds: 1));
    expect(cubit.state.speech, 'Where should the rook go?');
    expect(cubit.state.hintsShown, 0);
    expect(cubit.state.arrows, isEmpty);
    expect(cubit.state.layout, LessonLayoutMode.solving);
  });

  test('pensar: as dicas em ordem, a pedido, e "Ver explicação" segue para '
      'a explicação (o passo seguinte)', () async {
    final cubit = await open();
    await cubit.moreHint();
    expect(cubit.state.speech, 'Think about a bridge.');
    expect(cubit.state.arrows, [('c1', 'c4')]);
    await cubit.moreHint();
    expect(cubit.state.speech, 'The fourth rank.');
    expect(cubit.state.canHint, isFalse);
    expect(cubit.state.canContinue, isTrue);
    await cubit.next();
    expect(cubit.state.current?.id, 'demo');
    expect(cubit.state.layout, LessonLayoutMode.explaining);
  });

  test(
    'fechar no meio reabre no início da parte, com o cronômetro zerado',
    () async {
      final first = await open();
      await first.startStepClock();
      now.advance(const Duration(minutes: 1));
      await first.next();
      await first.close();
      now.advance(const Duration(seconds: 30));
      final again = await open();
      expect(again.state.current?.id, 'think');
      expect(again.stepElapsed, Duration.zero);
    },
  );

  test('checkpoint antigo com passo salvo é lido e reabre no início da '
      'parte', () async {
    progress.saved = EndgameProgress(
      ongoing: LessonCheckpoint(
        lessonId: 'rook.lucena',
        step: 1,
        part: 'bridge',
        stepId: 'demo',
        stepStartedAt: now.value,
      ),
    );
    final cubit = await open();
    expect(cubit.state.current?.id, 'think');
    expect(cubit.state.partNumber, 1);
    expect(progress.saved.ongoing?.step, 0);
  });

  test('checkpoint de outro passo reinicia o cronômetro em vez de trazer '
      'uma duração antiga', () async {
    progress.saved = EndgameProgress(
      ongoing: LessonCheckpoint(
        lessonId: 'rook.lucena',
        step: 0,
        part: 'bridge',
        stepId: 'demo',
        stepStartedAt: now.value.subtract(const Duration(hours: 23)),
      ),
    );
    final cubit = await open();
    expect(cubit.state.current?.id, 'think');
    expect(cubit.stepElapsed, Duration.zero);
    expect(progress.saved.ongoing?.stepId, 'think');
  });

  test(
    'fechar com uma dica mostrada reabre sem ela (início da parte)',
    () async {
      final first = await open();
      await first.moreHint();
      await first.close();
      final again = await open();
      expect(again.state.hintsShown, 0);
      expect(again.state.current?.id, 'think');
    },
  );

  test('layout: o exercício fica resolvendo até a resposta; a demonstração e '
      'a conversa, sempre com o professor falando', () async {
    final cubit = await open();
    await cubit.next();
    expect(cubit.state.current?.id, 'demo');
    expect(cubit.state.layout, LessonLayoutMode.explaining);
    await cubit.demoForward();
    await cubit.demoForward();
    await cubit.next();
    expect(cubit.state.current?.id, 'try');
    expect(cubit.state.layout, LessonLayoutMode.solving);
    expect(cubit.stepElapsed, Duration.zero);
    await cubit.play(Move.parse('c1c4')!);
    expect(cubit.state.phase, StepPhase.done);
    expect(cubit.state.layout, LessonLayoutMode.explaining);
    expect(
      (await open(part: 'final')).state.layout,
      LessonLayoutMode.explaining,
    );
  });

  Future<LessonCubit> atDemo() async {
    final cubit = await open();
    await cubit.next();
    return cubit;
  }

  test('demonstração: avança lance a lance, com a fala de cada um', () async {
    final cubit = await atDemo();
    expect(cubit.state.speech, 'Watch.');
    expect(cubit.state.canContinue, isFalse);
    await cubit.demoForward();
    expect(cubit.state.demoMove, 1);
    expect(cubit.state.speech, 'The rook builds the bridge.');
    expect(cubit.state.arrows, [('c4', 'b4')]);
    expect(cubit.state.lastMove, Move.parse('c1c4'));
    await cubit.demoForward();
    expect(cubit.state.speech, 'Black checks.');
    expect(cubit.state.phase, StepPhase.done);
    expect(cubit.state.canContinue, isTrue);
  });

  test(
    'demonstração: voltar desfaz e pausa; repetir volta ao começo',
    () async {
      final cubit = await atDemo();
      await cubit.demoForward();
      await cubit.demoForward();
      await cubit.demoBack();
      expect(cubit.state.demoMove, 1);
      expect(cubit.state.demoPlaying, isFalse);
      expect(cubit.state.speech, 'The rook builds the bridge.');
      // Avançar faz a demonstração voltar a andar sozinha.
      await cubit.demoForward();
      expect(cubit.state.demoPlaying, isFalse);
      await cubit.demoReplay();
      expect(cubit.state.demoMove, 0);
      expect(cubit.state.fen, fen);
    },
  );

  test('demonstração: pausar e retomar', () async {
    final cubit = await atDemo();
    expect(cubit.state.demoPlaying, isTrue);
    cubit.demoTogglePause();
    expect(cubit.state.demoPlaying, isFalse);
    cubit.demoTogglePause();
    expect(cubit.state.demoPlaying, isTrue);
  });

  test('fim da parte: grava a parte e oferece a próxima', () async {
    final cubit = await atDemo();
    await cubit.demoForward();
    await cubit.demoForward();
    await cubit.next();
    await cubit.play(Move.parse('c1c4')!);
    await cubit.next();
    expect(cubit.state.finished, isTrue);
    expect(cubit.state.nextPart, 'final');
    expect(progress.saved.of('rook.lucena').parts, {'bridge'});
    expect(progress.saved.of('rook.lucena').lessonDone, isFalse);
  });

  test(
    'progresso antigo (passo da aula inteira) abre na parte certa',
    () async {
      progress.saved = const EndgameProgress(
        ongoing: LessonCheckpoint(lessonId: 'rook.lucena', step: 3),
      );
      final cubit = await open();
      expect(cubit.state.part?.id, 'final');
      expect(cubit.state.current?.id, 'end');
    },
  );

  group('P1: reabrir numa parte que virou roteiro', () {
    EndgameTrail trailWith(List<LessonPart> parts) => EndgameTrail(
      modules: [
        EndgameModule(
          id: 'rook',
          lessons: [
            EndgameLesson(
              id: 'rook.lucena',
              module: 'rook',
              lesson: Lesson.parted(id: 'rook.lucena', parts: parts),
              exercises: const [],
              passScore: 0,
              keyPositions: const [],
              practice: const Practice(fen: fen, goal: PositionGoal.win),
            ),
          ],
        ),
      ],
    );

    Future<LessonCubit> reopen(List<LessonPart> parts) async {
      final cubit = LessonCubit(
        source: EndgameLessonSource(
          FakeEndgameLessonRepository(trail: trailWith(parts), texts: texts),
          progress,
        ),
        characters: FakeCharacterRepository(),
        opponent: FakeOpponentRepository(),
        now: now,
        replyDelay: Duration.zero,
      );
      addTearDown(cubit.close);
      // O app reabre sem a parte: ela vem do checkpoint.
      await cubit.load('rook.lucena', 'en');
      return cubit;
    }

    setUp(() {
      progress.saved = const EndgameProgress(
        ongoing: LessonCheckpoint(
          lessonId: 'rook.lucena',
          part: 'roteiro',
          step: 3,
        ),
      );
    });

    test(
      'a parte com roteiro manda para a tela de roteiro, sem erro',
      () async {
        final cubit = await reopen(const [
          LessonPart(
            id: 'bridge',
            steps: [TalkStep(id: 'end', fen: fen)],
          ),
          LessonPart(id: 'roteiro', steps: [], script: 'roteiro.json'),
        ]);
        expect(cubit.state.toScript, isTrue);
        expect(cubit.state.part?.id, 'roteiro');
        expect(cubit.state.lesson?.id, 'rook.lucena');
        // O roteiro retoma pelo checkpoint dele: não se descarta.
        expect(progress.saved.ongoing?.part, 'roteiro');
      },
    );

    test('a parte sem passos nem roteiro descarta o checkpoint', () async {
      final cubit = await reopen(const [
        LessonPart(
          id: 'bridge',
          steps: [TalkStep(id: 'end', fen: fen)],
        ),
        LessonPart(id: 'roteiro', steps: []),
      ]);
      expect(cubit.state.missing, isTrue);
      expect(cubit.state.toScript, isFalse);
      expect(progress.saved.ongoing, isNull);
    });
  });
}
