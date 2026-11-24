import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/video_turn.dart';

import '../../../testing/lesson_video_fixture.dart';

void main() {
  // Pergunta ideia.ex1.p do fixture: peça e2, certo e2e4, erro e2e3 (repete),
  // alternativa e1d1 (segue), fora → ideia.ex1.fora, revela ideia.ex1.revela.
  late VideoTurn turn;

  setUp(() {
    final gate = sampleLessonVideo().lines
        .firstWhere((l) => l.id == 'ideia.ex1.p')
        .gate!;
    turn = VideoTurn(gate);
  });

  test('Vídeo 28: lance certo segue sem ramo e sem ✗', () {
    final o = turn.judge('e2e4');
    expect(o.result, TurnResult.right);
    expect(o.resumes, isTrue);
    expect(o.branch, isNull);
    expect(o.wrongSquare, isNull);
    expect(turn.errors, 0);
  });

  test('Vídeo 26: erro conhecido toca a dica, ✗ no destino e espera', () {
    final o = turn.judge('e2e3');
    expect(o.result, TurnResult.wrong);
    expect(o.branch, 'ideia.ex1.err.e2e3');
    expect(o.wrongSquare, 'e3');
    expect(o.resumes, isFalse);
    expect(turn.errors, 1);
  });

  test('Vídeo 29: alternativa boa toca a fala própria e pula as do certo', () {
    final o = turn.judge('e1d1');
    expect(o.result, TurnResult.alternative);
    expect(o.branch, 'ideia.ex1.alt.e1d1');
    expect(o.resumes, isTrue);
    expect(o.skipsRightLines, isTrue);
    expect(turn.errors, 0);
  });

  test('Vídeo 30: lance fora da lista toca o ramo fora e espera', () {
    final o = turn.judge('e2e5');
    expect(o.result, TurnResult.outside);
    expect(o.branch, 'ideia.ex1.fora');
    expect(o.wrongSquare, 'e5');
    expect(o.resumes, isFalse);
  });

  test('Vídeo 30: peça fora de pecas marca o ✗ na casa da peça', () {
    final o = turn.judge('e1f1');
    expect(o.result, TurnResult.outside);
    expect(o.wrongSquare, 'e1');
  });

  test('Vídeo 27: "Ver a resposta" só a partir do 2º erro (decisão 5a)', () {
    expect(turn.canReveal, isFalse);
    expect(turn.reveal(), isNull);
    turn.judge('e2e3');
    expect(turn.canReveal, isFalse);
    turn.judge('e2e5');
    expect(turn.canReveal, isTrue);
    final o = turn.reveal()!;
    expect(o.result, TurnResult.revealed);
    expect(o.branch, 'ideia.ex1.revela');
    expect(o.resumes, isTrue);
    expect(o.skipsRightLines, isFalse);
  });

  test('movable são as peças da pergunta', () {
    expect(turn.movable, ['e2']);
  });
}
