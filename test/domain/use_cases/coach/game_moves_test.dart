import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/coach/game_moves.dart';

import '../../../../testing/coach_fixtures.dart';

void main() {
  group('LancesDaPartida.de', () {
    test('lê a linha principal do PGN, meio-lance a meio-lance', () {
      final moves = GameMoves.of(CoachFixtures.pgnTiago);
      expect(moves, hasLength(14));
      expect(moves.first.uci, 'e2e4');
      expect(moves.first.san, 'e4');
      expect(moves[1].san, 'c6');
      expect(moves.last.san, 'cxd4');
    });

    test('cada lance traz o FEN da posição depois dele', () {
      final moves = GameMoves.of(CoachFixtures.pgnTiago);
      expect(
        moves.first.fen,
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
      );
      Position position = Chess.initial;
      for (final chessMove in moves) {
        position = position.playUnchecked(Move.parse(chessMove.uci)!);
        expect(position.fen, chessMove.fen);
      }
    });

    test('o roque sai com a notação certa', () {
      final moves = GameMoves.of(CoachFixtures.pgnTiago);
      expect(moves.map((l) => l.san), contains('O-O'));
    });

    test('nulo, vazio e só espaços: lista vazia', () {
      expect(GameMoves.of(null), isEmpty);
      expect(GameMoves.of(''), isEmpty);
      expect(GameMoves.of('   \n '), isEmpty);
    });

    test('para no primeiro lance que não se joga', () {
      final moves = GameMoves.of('1. e4 e5 2. Rh9 Nc6 *');
      expect(moves.map((l) => l.san), ['e4', 'e5']);
    });
  });

  group('LancesDaPartida.inicio', () {
    test('sem FEN no PGN: a posição inicial', () {
      expect(GameMoves.start(CoachFixtures.pgnTiago), Chess.initial.fen);
    });

    test('nulo: a posição inicial', () {
      expect(GameMoves.start(null), Chess.initial.fen);
    });

    test('PGN com [FEN]: começa dali', () {
      const fen = CoachFixtures.fenEnding;
      final start = GameMoves.start('[SetUp "1"]\n[FEN "$fen"]\n\n1... Rb2 *');
      expect(start, fen);
    });
  });
}
