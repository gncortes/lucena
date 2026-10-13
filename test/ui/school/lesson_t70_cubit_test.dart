import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/engine_fallback.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

/// Fluxo da lição (T70, lote 1): o estado correto, o motor, o prático e a
/// demonstração, no cubit.
void main() {
  const id = 'test.t70';
  const start = '4k3/8/8/8/8/8/4P3/4K3 w - - 0 1';
  const afterE4 = '4k3/8/8/8/4P3/8/8/4K3 b - - 0 1';

  const texts = LessonTexts({
    'test.t70.t': ['Pense.'],
    'test.t70.talk': ['Explicação completa do plano.'],
    'test.t70.talk.short': ['Curta.'],
    'test.t70.t.mistake.e1d1': ['Texto do erro previsto.'],
    'test.t70.m.hint': ['Dica do Viktor.'],
    'test.t70.m.r1': ['Resposta ao primeiro lance.'],
    'test.t70.m.done': ['Feito.'],
    'test.t70.d.m1': ['Primeiro lance da demo.'],
    'coach.good': ['Bom lance.'],
    'test.t70.dw.m1': ['1...Kd8. O rei preto sai da coluna.'],
    'test.t70.p': ['Jogue de brancas e ache o lance.'],
    'test.t70.p.done': ['Passo feito.'],
  });

  const think = ThinkStep(
    id: 't',
    fen: start,
    accept: {'e2e3'},
    mistakes: {'e1d1': StepMistake(say: 'step.t.mistake.e1d1')},
  );
  const talk = TalkStep(id: 'talk', fen: afterE4, arrows: [('e2', 'e4')]);
  const end = TalkStep(id: 'end', fen: start);

  late FakeSchoolProgressRepository progress;

  LessonCubit make(
    List<LessonStep> steps, {
    EngineFallback? engine,
    bool practiceV2 = false,
  }) {
    final cubit = LessonCubit(
      lessons: FakeLessonRepository(
        course: Course(
          modules: [
            CourseModule(
              id: 'test',
              lessons: [Lesson(id: id, steps: steps)],
            ),
          ],
        ),
        texts: texts,
      ),
      progress: progress,
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
      holdDelay: Duration.zero,
      typingDelay: Duration.zero,
      engine: engine,
      practiceV2: practiceV2,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Move mv(String uci) => Move.parse(uci)!;

  EngineFallback engine(int score, {bool fail = false}) => EngineFallback(
    evaluate: (_, _) async =>
        fail ? throw StateError('x') : Evaluation(centipawns: score),
    bestMove: (p) async => mv('e8d8'),
  );

  setUp(() => progress = FakeSchoolProgressRepository());

  group('estado correto', () {
    test(
      'acerto, erro + Ver resposta e Ver resposta chegam ao mesmo estado',
      () async {
        final hit = make(const [think, talk, end], practiceV2: true);
        await hit.load(id, 'pt');
        await hit.play(mv('e2e4'));
        final miss = make(const [think, talk, end], practiceV2: true);
        await miss.load(id, 'pt');
        await miss.play(mv('e1d1'));
        expect(miss.state.step, 1);
        expect(miss.state.correct, isFalse);
        await miss.showAnswer();
        final direct = make(const [think, talk, end], practiceV2: true);
        await direct.load(id, 'pt');
        await direct.showAnswer();
        for (final s in [hit.state, miss.state, direct.state]) {
          expect(s.step, 1);
          expect(s.correct, isTrue);
          expect(s.fen, afterE4);
          expect(s.speech, 'Curta.');
          expect(s.fullSpeech, 'Explicação completa do plano.');
          expect(s.lastMove?.uci, 'e2e4');
        }
        hit.showFullExplanation();
        expect(hit.state.speech, 'Explicação completa do plano.');
        expect(hit.state.fullSpeech, isNull);
      },
    );

    test('o erro previsto abre o ramo com a fala e marca "já visto"', () async {
      final cubit = make(const [think, talk, end]);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e1d1'));
      expect(cubit.state.step, 1);
      expect(cubit.state.speech, contains('Texto do erro previsto.'));
      expect(cubit.state.thinkPlayed, 'e1d1');
      expect(cubit.state.seen, {'e1d1'});
    });

    test('dois lances corretos: o outro traz a nota e termina igual', () async {
      final cubit = make(const [think, talk, end]);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e2e3'));
      expect(cubit.state.correct, isTrue);
      expect(cubit.state.step, 1);
      expect(cubit.state.fen, afterE4);
    });

    test('sem ramo e sem motor: a peça volta e avisa', () async {
      final cubit = make(const [think, talk, end]);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e1f1'));
      expect(cubit.state.step, 0);
      expect(cubit.state.wrongNotice, isTrue);
      expect(cubit.state.fen, start);
      expect(cubit.state.mistakes, 1);
    });

    test('motor mantém: nota e estado correto', () async {
      final cubit = make(const [think, talk, end], engine: engine(900));
      await cubit.load(id, 'pt');
      await cubit.play(mv('e1f1'));
      expect(cubit.state.correct, isTrue);
      expect(cubit.state.fen, afterE4);
    });

    test('motor perde: abre o ramo com lance e resposta', () async {
      final cubit = make(const [think, talk, end], engine: engine(-300));
      await cubit.load(id, 'pt');
      await cubit.play(mv('e1f1'));
      expect(cubit.state.step, 1);
      expect(cubit.state.engineLine, ['e1f1', 'e8d8']);
      expect(cubit.state.note, LessonNote.engineMove);
      await cubit.showAnswer();
      expect(cubit.state.correct, isTrue);
    });

    test('motor falha: a peça volta e conta o erro do motor', () async {
      final cubit = make(const [
        think,
        talk,
        end,
      ], engine: engine(0, fail: true));
      await cubit.load(id, 'pt');
      await cubit.play(mv('e1f1'));
      expect(cubit.state.step, 0);
      expect(cubit.state.engineErrors, 1);
      expect(cubit.state.fen, start);
      expect(cubit.state.typing, isFalse);
    });
  });

  group('prático', () {
    const move = MoveStep(
      id: 'm',
      fen: start,
      line: [
        MoveTurn(accept: {'e2e4'}, reply: 'e8d8'),
        MoveTurn(accept: {'e4e5'}),
      ],
    );

    test('convite antes do primeiro lance; Voltar volta ao convite', () async {
      final cubit = make(const [talk, move], practiceV2: true);
      await cubit.load(id, 'pt');
      await cubit.next();
      expect(cubit.state.step, 1);
      expect(cubit.state.practiceGate, isTrue);
      expect(cubit.state.interactive, isFalse);
      cubit.startPractice();
      expect(cubit.state.practiceGate, isFalse);
      expect(cubit.state.interactive, isTrue);
    });

    test('Voltar desfaz o par e Continuar o refaz; lance novo limpa', () async {
      final cubit = make(const [move], practiceV2: true);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e2e4'));
      expect(cubit.state.turn, 1);
      expect(cubit.state.speech, 'Resposta ao primeiro lance.');
      final after = cubit.state.fen;
      await cubit.practiceBack();
      expect(cubit.state.fen, start);
      expect(cubit.state.turn, 0);
      expect(cubit.state.canRedo, isTrue);
      await cubit.practiceForward();
      expect(cubit.state.fen, after);
      expect(cubit.state.turn, 1);
      expect(cubit.state.canRedo, isFalse);
      await cubit.practiceBack();
      await cubit.play(mv('e2e4'));
      expect(cubit.state.canRedo, isFalse);
    });

    test(
      'fora da linha com motor: lance + resposta, descartado no Voltar',
      () async {
        final cubit = make(
          const [move],
          engine: engine(-300),
          practiceV2: true,
        );
        await cubit.load(id, 'pt');
        await cubit.play(mv('e1f1'));
        expect(cubit.state.offLine, isTrue);
        expect(cubit.state.interactive, isFalse);
        final after = cubit.state.fen;
        await cubit.practiceBack();
        expect(cubit.state.offLine, isFalse);
        expect(cubit.state.fen, start);
        // O Continuar refaz também o par jogado pelo motor (4.7).
        expect(cubit.state.canRedo, isTrue);
        await cubit.practiceForward();
        expect(cubit.state.fen, after);
        expect(cubit.state.offLine, isTrue);
        expect(cubit.state.canRedo, isFalse);
      },
    );

    test('sem r<n> o balão comenta o lance com coach.good e o Voltar o '
        'devolve ao comentário anterior', () async {
      const plain = MoveStep(
        id: 'p',
        fen: start,
        line: [
          MoveTurn(accept: {'e2e4'}, reply: 'e8d8'),
          MoveTurn(accept: {'e4e5'}, reply: 'd8e8'),
          MoveTurn(accept: {'e5e6'}),
        ],
      );
      final cubit = make(const [plain], practiceV2: true);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e2e4'));
      expect(cubit.state.speech, 'Bom lance.');
      await cubit.play(mv('e4e5'));
      expect(cubit.state.speech, 'Bom lance.');
      await cubit.play(mv('e5e6'));
      expect(cubit.state.speech, 'Passo feito.');
      await cubit.practiceBack();
      expect(cubit.state.speech, 'Bom lance.');
      await cubit.practiceBack();
      await cubit.practiceBack();
      // De volta ao início: o enunciado do próprio passo.
      expect(cubit.state.speech, 'Jogue de brancas e ache o lance.');
    });

    test('o balão abre com a fala do passo, não com a do pensar', () async {
      const plain = MoveStep(
        id: 'p',
        fen: start,
        line: [
          MoveTurn(accept: {'e2e4'}),
        ],
      );
      final cubit = make(const [think, talk, plain], practiceV2: true);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e2e3'));
      await cubit.next();
      expect(cubit.state.practiceGate, isTrue);
      cubit.startPractice();
      expect(cubit.state.speech, 'Jogue de brancas e ache o lance.');
    });

    test('a dica fica só no balão, sem seta', () async {
      final cubit = make(const [move], practiceV2: true);
      await cubit.load(id, 'pt');
      await cubit.askHint();
      expect(cubit.state.practiceHint, isTrue);
      expect(cubit.state.hint, isNull);
      expect(cubit.state.speech, 'Dica do Viktor.');
    });
  });

  group('ramo do erro do pensar', () {
    const wrongDemo = DemoStep(
      id: 'dw',
      fen: '4k3/8/8/8/8/8/4P3/3K4 b - - 1 1',
      wrong: true,
      line: [
        DemoMove(uci: 'e8d8'),
        DemoMove(uci: 'd1c1'),
      ],
    );

    test('segue a demo errada ligada ao erro, texto por lance', () async {
      final cubit = make(const [think, talk, wrongDemo]);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e1d1'));
      final branch = cubit.thinkBranch('e1d1', fallback: 'Neutro.');
      expect(branch.ucis, ['e1d1', 'e8d8', 'd1c1']);
      // 1) a fala do erro; 2) a da demo sem o lance na frente; 3) sem texto.
      expect(branch.texts, [
        'Texto do erro previsto.',
        'O rei preto sai da coluna.',
        '',
      ]);
    });

    test('alternativa sem ramo nos dados: só o lance, texto neutro', () async {
      final cubit = make(const [think, talk, wrongDemo]);
      await cubit.load(id, 'pt');
      await cubit.play(mv('e2e3'));
      final branch = cubit.thinkBranch('e1f1', fallback: 'Neutro.');
      expect(branch.ucis, ['e1f1']);
      expect(branch.texts, ['Neutro.']);
    });
  });

  group('demonstração', () {
    const demo = DemoStep(
      id: 'd',
      fen: start,
      line: [
        DemoMove(uci: 'e2e4'),
        DemoMove(uci: 'e8d8'),
      ],
    );

    test('demoForward mantém a pausa', () async {
      final cubit = make(const [demo]);
      await cubit.load(id, 'pt');
      cubit.demoTogglePause();
      expect(cubit.state.demoPlaying, isFalse);
      await cubit.demoForward();
      expect(cubit.state.demoMove, 1);
      expect(cubit.state.demoPlaying, isFalse);
    });

    test(
      'lance do aluno em pausa: o motor responde; voltar ao roteiro',
      () async {
        final cubit = make(const [demo], engine: engine(900));
        await cubit.load(id, 'pt');
        cubit.demoTogglePause();
        await cubit.demoPlay(mv('e1f1'));
        expect(cubit.state.offScript, isTrue);
        expect(cubit.state.demoOff, ['e1f1', 'e8d8']);
        await cubit.demoBack();
        expect(cubit.state.offScript, isFalse);
        expect(cubit.state.fen, start);
        await cubit.demoPlay(mv('e1f1'));
        await cubit.demoBackToScript();
        expect(cubit.state.offScript, isFalse);
        expect(cubit.state.demoMove, 0);
      },
    );

    test('o próximo lance do roteiro vale como avançar', () async {
      final cubit = make(const [demo], engine: engine(900));
      await cubit.load(id, 'pt');
      cubit.demoTogglePause();
      await cubit.demoPlay(mv('e2e4'));
      expect(cubit.state.demoMove, 1);
      expect(cubit.state.offScript, isFalse);
    });
  });
}
