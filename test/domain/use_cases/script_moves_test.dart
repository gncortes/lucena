import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/script_moves.dart';

Set<String> _names(Set<Square>? squares) => {
  for (final square in squares ?? const <Square>{}) square.name,
};

void main() {
  group('sem rei (lição de peça)', () {
    const rook = '8/8/2P5/8/8/8/8/2R5 w - - 0 1';

    test('os destinos seguem os ataques da peça', () {
      final dests = ScriptMoves.dests(rook, pieces: ['c1']);
      expect(dests.keys.map((s) => s.name), ['c1']);
      expect(_names(dests[Square.c1]), {
        'a1', 'b1', 'd1', 'e1', 'f1', 'g1', 'h1', //
        'c2', 'c3', 'c4', 'c5',
      });
    });

    test('peça fora da lista não mexe', () {
      expect(ScriptMoves.dests(rook, pieces: ['c6']), isEmpty);
      expect(ScriptMoves.legal(rook, 'c6c7', pieces: ['c1']), isNull);
    });

    test('jogar mantém a vez e anota o lance à mão', () {
      final played = ScriptMoves.play(rook, 'c1d1', keepTurn: true)!;
      expect(played.fen, '8/8/2P5/8/8/8/8/3R4 w - - 0 1');
      expect(played.san, 'Rd1');
    });

    test('captura leva o x', () {
      const fen = '8/8/2p5/8/8/8/8/2R5 w - - 0 1';
      expect(ScriptMoves.play(fen, 'c1c6', keepTurn: true)!.san, 'Rxc6');
    });

    test('lance que a peça não faz é nulo', () {
      expect(ScriptMoves.legal(rook, 'c1d2'), isNull);
      expect(ScriptMoves.play(rook, 'c1c7'), isNull);
    });
  });

  group('com rei (regras do xadrez)', () {
    const king = 'k4r2/8/8/8/8/8/8/4K3 w - - 0 1';

    test('o rei não pisa em casa atacada', () {
      final dests = ScriptMoves.dests(king, pieces: ['e1']);
      expect(_names(dests[Square.e1]), {'d1', 'd2', 'e2'});
    });

    test('tarefa: a vez não passa', () {
      final played = ScriptMoves.play(king, 'e1d2', keepTurn: true)!;
      expect(played.fen.split(' ')[1], 'w');
      expect(played.san, 'Kd2');
      final game = ScriptMoves.play(king, 'e1d2')!;
      expect(game.fen.split(' ')[1], 'b');
    });

    test('peão que coroa sem escolher vira dama', () {
      const fen = '4k3/6P1/8/8/8/8/8/4K3 w - - 0 1';
      expect(ScriptMoves.legal(fen, 'g7g8'), 'g7g8q');
    });
  });
}
