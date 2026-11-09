import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/domain/use_cases/treinador/revisao_da_partida.dart';

import '../../../../testing/treinador_fixtures.dart';

void main() {
  group('RevisaoDaPartida', () {
    test('leva os lances, o lado, o resultado e o adversário', () {
      final jogo = RevisaoDaPartida.de(TreinadorFixtures.tiago());

      expect(jogo.moves, hasLength(14));
      expect(jogo.moves.first, 'e2e4');
      expect(jogo.userSide, Side.black);
      expect(jogo.outcome, AttemptOutcome.loss);
      expect(jogo.opponentName, 'Tiago_Rook');
      expect(jogo.selected, isNull);
    });

    test('a classe do servidor vira a qualidade do lance', () {
      final review = RevisaoDaPartida.de(
        TreinadorFixtures.tiago(),
        peso: 5,
      ).review!;

      expect(review.moves, hasLength(14));
      // 6...Qb6 é "erro"; os outros são "ok" e nunca aparecem como falha.
      expect(review.moves[11].quality, MoveQuality.mistake);
      for (final (i, m) in review.moves.indexed) {
        if (i != 11) expect(m.quality.isError, isFalse, reason: 'lance $i');
      }
      expect(review.moves[11].weight, 5);
      expect(review.moves[11].best, 'c8d7');
      // A precisão do jogador (pretas) é a do servidor.
      expect(review.blackAccuracy, 78);
    });

    test('o comentário do servidor fica no lance dele', () {
      final jogo = RevisaoDaPartida.de(TreinadorFixtures.tiago());

      expect(jogo.comments.keys, [11]);
      expect(jogo.comments[11], startsWith('A dama sai cedo'));
    });

    test('?lance abre o meio-lance pedido, preso ao intervalo', () {
      final partida = TreinadorFixtures.tiago();

      expect(RevisaoDaPartida.de(partida, lance: 12).selected, 11);
      expect(RevisaoDaPartida.de(partida, lance: 0).selected, -1);
      expect(RevisaoDaPartida.de(partida, lance: 999).selected, 13);
    });

    test('sem os lances analisados, fica sem revisão (a engine anota)', () {
      final partida = PartidaTreinador.fromJson(
        TreinadorFixtures.idTiago,
        TreinadorFixtures.tiagoJson(status: 'analisando'),
      )!;

      final jogo = RevisaoDaPartida.de(partida);

      expect(jogo.review, isNull);
      expect(jogo.moves, hasLength(14));
    });
  });
}
