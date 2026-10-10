import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';

void main() {
  const step = MoveStep(
    id: 'bridge',
    fen: '1K1k4/1P6/8/8/8/8/r7/2R5 w - - 0 1',
    line: [
      MoveTurn(accept: {'c1c4', 'c1c5'}, reply: 'a2a1'),
      MoveTurn(accept: {'c4c5', 'c4c6'}),
    ],
  );

  test('só os lances da vez são aceitos', () {
    expect(LessonRules.accepts(step, 0, 'c1c4'), isTrue);
    expect(LessonRules.accepts(step, 0, 'c1c5'), isTrue);
    expect(LessonRules.accepts(step, 0, 'c4c5'), isFalse);
    expect(LessonRules.accepts(step, 2, 'c1c4'), isFalse);
  });

  test('a linha segue só pelo lance ensinado; outro bom a encerra', () {
    expect(LessonRules.endsLine(step, 0, 'c1c4'), isFalse);
    expect(LessonRules.endsLine(step, 0, 'c1c5'), isTrue);
    // Na última vez, qualquer aceito encerra.
    expect(LessonRules.endsLine(step, 1, 'c4c5'), isTrue);
    expect(LessonRules.endsLine(step, 1, 'c4c6'), isTrue);
  });

  test('T60: reconhece a fala que já diz quem joga, em português e inglês', () {
    for (final text in [
      'Brancas jogam. Três peões contra três.',
      'Você joga de pretas e defende.',
      'Jogam as brancas.',
      'White to move. What is the plan?',
      'You play Black here.',
    ]) {
      expect(LessonRules.saysWhoMoves(text), isTrue, reason: text);
    }
    for (final text in [
      'Torre preta atacando o seu peão pelo lado.',
      'The black rook attacks your pawn from the side.',
    ]) {
      expect(LessonRules.saysWhoMoves(text), isFalse, reason: text);
    }
  });

  test('o enunciado do passo de pensar abre a explicação sem as perguntas', () {
    expect(
      LessonRules.thinkContext(
        'Brancas jogam. O rei preto está longe do peão, e o branco também. '
        'Se o rei preto alcançar o peão de f, é empate. Qual lance de rei '
        'impede isso?',
      ),
      'O rei preto está longe do peão, e o branco também. '
      'Se o rei preto alcançar o peão de f, é empate.',
    );
    expect(LessonRules.thinkContext('White to move. What is the plan?'), '');
  });
}
