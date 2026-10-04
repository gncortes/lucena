import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/position_validation.dart';

void main() {
  PositionProblem? problem(String fen) => PositionValidation.check(fen).problem;

  test('posição jogável volta pronta, com o lado que joga', () {
    final check = PositionValidation.check('4k3/8/8/8/8/8/4P3/4K3 b - - 0 1');

    expect(check.problem, isNull);
    expect(check.position?.turn, Side.black);
  });

  test('texto que não é FEN', () {
    expect(problem('isto não é FEN'), PositionProblem.invalidFen);
    expect(problem('4k3/8/8 w - - 0 1'), PositionProblem.invalidFen);
  });

  test('sem rei: diz qual rei falta', () {
    expect(
      problem('8/8/8/8/8/8/4P3/4K3 w - - 0 1'),
      PositionProblem.missingBlackKing,
    );
    expect(
      problem('4k3/8/8/8/8/8/4P3/8 w - - 0 1'),
      PositionProblem.missingWhiteKing,
    );
  });

  test('dois reis do mesmo lado', () {
    expect(
      problem('4k3/8/8/8/8/8/8/K3K3 w - - 0 1'),
      PositionProblem.tooManyKings,
    );
  });

  test('tabuleiro vazio', () {
    expect(problem('8/8/8/8/8/8/8/8 w - - 0 1'), PositionProblem.empty);
  });

  test('o lado que não joga está em xeque', () {
    // Pretas em xeque da torre, mas é a vez das brancas.
    expect(problem('4k3/8/8/8/8/8/8/R3K3 w - - 0 1'), isNull);
    expect(
      problem('R3k3/8/8/8/8/8/8/4K3 w - - 0 1'),
      PositionProblem.oppositeCheck,
    );
  });

  test('peão na última fileira', () {
    expect(
      problem('P3k3/8/8/8/8/8/8/4K3 w - - 0 1'),
      PositionProblem.pawnsOnBackrank,
    );
  });

  test('partida que já acabou: mate, afogamento ou só os reis', () {
    expect(
      problem('4k3/8/8/8/8/8/8/4K3 w - - 0 1'),
      PositionProblem.alreadyOver,
    );
    expect(
      problem('7k/5Q2/6K1/8/8/8/8/8 b - - 0 1'),
      PositionProblem.alreadyOver,
    );
  });
}
