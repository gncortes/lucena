import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';

/// T51, C3: a lição de uma aula em partes, o passo de pensar (timer e
/// dicas) e a demonstração (o professor joga).
void main() {
  const fen = FakeEndgameLessonRepository.lucenaFen;
  final lesson = Lesson.parted(
    id: 'rook.lucena',
    parts: const [
      LessonPart(
        id: 'bridge',
        steps: [
          ThinkStep(
            id: 'think',
            fen: fen,
            minutes: 3,
            hints: 2,
            arrows: [('c1', 'c4')],
          ),
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
              MoveTurn(accept: {'c1c4'}),
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

  Future<LessonCubit> open({String? part, int thinkMinutes = 0}) async {
    final cubit = LessonCubit(
      settings: FakeSettingsRepository(AppSettings(thinkMinutes: thinkMinutes)),
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

  test('pensar: sem dica nem "Ver explicação" antes do tempo', () async {
    final cubit = await open();
    expect(cubit.state.thinking, isTrue);
    expect(cubit.state.canContinue, isFalse);
    expect(cubit.state.canHint, isFalse);
    expect(cubit.state.arrows, isEmpty);
    now.advance(const Duration(minutes: 1));
    await cubit.tick();
    expect(cubit.state.thinkLeft, const Duration(minutes: 2));
    await cubit.next();
    expect(cubit.state.current?.id, 'think');
  });

  test(
    'pensar: no fim do tempo, as dicas em ordem e "Ver explicação"',
    () async {
      final cubit = await open();
      now.advance(const Duration(minutes: 3));
      await cubit.tick();
      expect(cubit.state.thinking, isFalse);
      // Primeiro a pergunta-guia; as setas vêm com a primeira dica.
      expect(cubit.state.speech, 'Where should the rook go?');
      expect(cubit.state.arrows, isEmpty);
      expect(cubit.state.canHint, isTrue);
      expect(cubit.state.canContinue, isTrue);
      await cubit.moreHint();
      expect(cubit.state.speech, 'Think about a bridge.');
      expect(cubit.state.arrows, [('c1', 'c4')]);
      await cubit.moreHint();
      expect(cubit.state.speech, 'The fourth rank.');
      expect(cubit.state.canHint, isFalse);
      expect(cubit.state.canContinue, isTrue);
      await cubit.next();
      expect(cubit.state.current?.id, 'demo');
    },
  );

  test('pensar: pular vai direto à explicação', () async {
    final cubit = await open();
    await cubit.skipThink();
    expect(cubit.state.current?.id, 'demo');
  });

  test(
    'pensar: o recomendado é o tempo da posição; fixado, o escolhido',
    () async {
      // Recomendado (o padrão): os 3 minutos que a posição pede.
      expect((await open()).state.thinkLeft, const Duration(minutes: 3));
      final fixed = await open(thinkMinutes: 1);
      expect(fixed.state.thinkLeft, const Duration(minutes: 1));
    },
  );

  test('pensar: jogou um lance, a explicação vem logo, sem relógio', () async {
    final cubit = await open();
    final states = <LessonState>[];
    final sub = cubit.stream.listen(states.add);
    addTearDown(sub.cancel);
    await cubit.play(Move.parse('c1c3')!);
    // O relógio some junto com o lance, antes de trocar de passo.
    expect(states.first.thinking, isFalse);
    expect(states.first.fen, isNot(fen));
    expect(cubit.state.current?.id, 'demo');
  });

  test('pensar: depois do tempo, mexe as peças à vontade e "Voltar à posição" '
      'restaura', () async {
    final cubit = await open();
    now.advance(const Duration(minutes: 3));
    await cubit.tick();
    await cubit.play(Move.parse('c1c3')!);
    expect(cubit.state.current?.id, 'think');
    expect(cubit.state.fen, isNot(fen));
    cubit.resetThink();
    expect(cubit.state.fen, fen);
  });

  test('pensar: fechar no meio volta com o tempo certo', () async {
    final first = await open();
    now.advance(const Duration(minutes: 1));
    await first.tick();
    await first.close();
    // Reabre 30 s depois: falta 1 min 30 s, contado desde o começo.
    now.advance(const Duration(seconds: 30));
    final again = await open();
    expect(again.state.current?.id, 'think');
    expect(again.state.thinkLeft, const Duration(minutes: 1, seconds: 30));
  });

  test('pensar: tempo acabado com o app fechado volta já com a dica', () async {
    final first = await open();
    await first.close();
    now.advance(const Duration(minutes: 10));
    final again = await open();
    expect(again.state.thinking, isFalse);
    expect(again.state.hintsShown, 0);
    expect(again.state.speech, 'Where should the rook go?');
  });

  Future<LessonCubit> atDemo() async {
    final cubit = await open();
    now.advance(const Duration(minutes: 3));
    await cubit.tick();
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
