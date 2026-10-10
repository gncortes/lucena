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
  final texts = LessonTexts.fromJson({
    'rook.lucena.think': 'Where should the rook go?',
    'rook.lucena.think.hint1': 'Think about a bridge.',
    'rook.lucena.think.hint2': 'The fourth rank.',
    'rook.lucena.demo': 'Watch.',
    'rook.lucena.demo.m1': 'The rook builds the bridge.',
    'rook.lucena.demo.m2': 'Black checks.',
    'coach.thinkRight': ['Correct!'],
  });
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

  Future<LessonCubit> open({String? part}) async {
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(trail: trail, texts: texts),
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

  test('pensar: o lance certo segue no tabuleiro, com "correto"', () async {
    final cubit = await open();
    await cubit.play(Move.parse('c1c4')!);
    expect(cubit.state.current?.id, 'demo');
    // A demonstração já começa depois do lance do aluno, sem refazê-lo.
    expect(cubit.state.demoMove, 1);
    expect(cubit.state.lastMove, Move.parse('c1c4'));
    expect(cubit.state.speech, startsWith('Correct!'));
  });

  test('pensar: outro lance aceito também é "correto", sem seguir no '
      'tabuleiro', () async {
    final cubit = await open();
    await cubit.play(Move.parse('c1c5')!);
    expect(cubit.state.current?.id, 'demo');
    expect(cubit.state.demoMove, 0);
    expect(cubit.state.speech, startsWith('Correct!'));
  });

  test('pensar: lance diferente abre a explicação do começo', () async {
    final cubit = await open();
    await cubit.play(Move.parse('c1c2')!);
    expect(cubit.state.current?.id, 'demo');
    expect(cubit.state.demoMove, 0);
    expect(cubit.state.speech, isNot(startsWith('Correct!')));
  });

  test('cronômetro: zero ao abrir, cresce, e passar de 6 minutos não muda '
      'nada', () async {
    final cubit = await open();
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
    'fechar no meio volta com o cronômetro contando desde o começo',
    () async {
      final first = await open();
      now.advance(const Duration(minutes: 1));
      await first.close();
      // Reabre 30 s depois: 1 min 30 s, contado desde o começo.
      now.advance(const Duration(seconds: 30));
      final again = await open();
      expect(again.state.current?.id, 'think');
      expect(again.stepElapsed, const Duration(minutes: 1, seconds: 30));
    },
  );

  test(
    'checkpoint de antes da T60 (thinkStartedAt) restaura o cronômetro',
    () async {
      progress.saved = EndgameProgress(
        ongoing: LessonCheckpoint.fromJson({
          'lesson': 'rook.lucena',
          'step': 0,
          'part': 'bridge',
          'open': true,
          'thinkStartedAt': now.value
              .subtract(const Duration(minutes: 2))
              .toIso8601String(),
        }),
      );
      final cubit = await open();
      expect(cubit.state.current?.id, 'think');
      expect(cubit.stepElapsed, const Duration(minutes: 2));
    },
  );

  test('fechar com uma dica mostrada volta com ela', () async {
    final first = await open();
    await first.moreHint();
    await first.close();
    final again = await open();
    expect(again.state.hintsShown, 1);
    expect(again.state.speech, 'Think about a bridge.');
    expect(again.state.arrows, [('c1', 'c4')]);
  });

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
}
