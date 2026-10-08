import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';

/// O passo de jogar com objetivo de empatar (as aulas de defesa): antes,
/// "draw" virava "dar o mate" e a aula nunca acabava.
void main() {
  Position at(String fen) => Chess.fromSetup(Setup.parseFen(fen));

  test('"draw" no arquivo vira o objetivo de empatar', () {
    expect(PlayGoal.fromCode('draw'), PlayGoal.draw);
    expect(PlayGoal.fromCode('promote'), PlayGoal.promote);
    expect(PlayGoal.fromCode('win'), PlayGoal.mate);
    expect(PlayGoal.fromCode(null), PlayGoal.mate);
  });

  // Philidor, aluno de brancas: torre e peão das pretas.
  const philidor = '8/8/8/8/4pk2/8/r7/1R2K3 w - - 0 1';

  test('empatar: com peão no tabuleiro e poucos lances, segue', () {
    expect(
      LessonRules.resultOf(
        at(philidor),
        goal: PlayGoal.draw,
        student: Side.white,
        studentMoves: 3,
      ),
      PlayResult.ongoing,
    );
  });

  test('empatar: segurar os lances pedidos conta como empate', () {
    expect(
      LessonRules.resultOf(
        at(philidor),
        goal: PlayGoal.draw,
        student: Side.white,
        studentMoves: LessonRules.holdMoves,
      ),
      PlayResult.success,
    );
  });

  test('empatar: o peão saiu do tabuleiro (só torres) conta como empate', () {
    expect(
      LessonRules.resultOf(
        at('8/8/8/8/5k2/8/r7/1R2K3 w - - 0 1'),
        goal: PlayGoal.draw,
        student: Side.white,
        studentMoves: 2,
      ),
      PlayResult.success,
    );
  });

  test('empatar: tomar mate é derrota', () {
    expect(
      LessonRules.resultOf(
        at('4k3/8/8/8/8/8/r7/r3K3 w - - 0 1'),
        goal: PlayGoal.draw,
        student: Side.white,
        studentMoves: 30,
      ),
      PlayResult.lost,
    );
  });

  test('empatar: afogamento conta como empate', () {
    expect(
      LessonRules.resultOf(
        at('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
        goal: PlayGoal.draw,
        student: Side.black,
      ),
      PlayResult.success,
    );
  });
}
