import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/treinador/lances_da_partida.dart';

import '../../../../testing/treinador_fixtures.dart';

void main() {
  group('LancesDaPartida.de', () {
    test('lê a linha principal do PGN, meio-lance a meio-lance', () {
      final lances = LancesDaPartida.de(TreinadorFixtures.pgnTiago);
      expect(lances, hasLength(14));
      expect(lances.first.uci, 'e2e4');
      expect(lances.first.san, 'e4');
      expect(lances[1].san, 'c6');
      expect(lances.last.san, 'cxd4');
    });

    test('cada lance traz o FEN da posição depois dele', () {
      final lances = LancesDaPartida.de(TreinadorFixtures.pgnTiago);
      expect(
        lances.first.fen,
        'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1',
      );
      Position posicao = Chess.initial;
      for (final lance in lances) {
        posicao = posicao.playUnchecked(Move.parse(lance.uci)!);
        expect(posicao.fen, lance.fen);
      }
    });

    test('o roque sai com a notação certa', () {
      final lances = LancesDaPartida.de(TreinadorFixtures.pgnTiago);
      expect(lances.map((l) => l.san), contains('O-O'));
    });

    test('nulo, vazio e só espaços: lista vazia', () {
      expect(LancesDaPartida.de(null), isEmpty);
      expect(LancesDaPartida.de(''), isEmpty);
      expect(LancesDaPartida.de('   \n '), isEmpty);
    });

    test('para no primeiro lance que não se joga', () {
      final lances = LancesDaPartida.de('1. e4 e5 2. Rh9 Nc6 *');
      expect(lances.map((l) => l.san), ['e4', 'e5']);
    });
  });

  group('LancesDaPartida.inicio', () {
    test('sem FEN no PGN: a posição inicial', () {
      expect(
        LancesDaPartida.inicio(TreinadorFixtures.pgnTiago),
        Chess.initial.fen,
      );
    });

    test('nulo: a posição inicial', () {
      expect(LancesDaPartida.inicio(null), Chess.initial.fen);
    });

    test('PGN com [FEN]: começa dali', () {
      const fen = TreinadorFixtures.fenFinal;
      final inicio = LancesDaPartida.inicio(
        '[SetUp "1"]\n[FEN "$fen"]\n\n1... Rb2 *',
      );
      expect(inicio, fen);
    });
  });
}
