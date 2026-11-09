import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:lucena/domain/use_cases/coach/coach_game_review.dart';

import '../../../../testing/coach_fixtures.dart';

void main() {
  group('RevisaoDaPartida', () {
    test('leva os lances, o lado, o resultado e o adversário', () {
      final match = CoachGameReview.of(CoachFixtures.tiago());

      expect(match.moves, hasLength(14));
      expect(match.moves.first, 'e2e4');
      expect(match.userSide, Side.black);
      expect(match.outcome, AttemptOutcome.loss);
      expect(match.opponentName, 'Tiago_Rook');
      expect(match.selected, isNull);
    });

    test('a classe do servidor vira a qualidade do lance', () {
      final review = CoachGameReview.of(
        CoachFixtures.tiago(),
        weight: 5,
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
      final match = CoachGameReview.of(CoachFixtures.tiago());

      expect(match.comments.keys, [11]);
      expect(match.comments[11], startsWith('A dama sai cedo'));
    });

    test('?lance abre o meio-lance pedido, preso ao intervalo', () {
      final game = CoachFixtures.tiago();

      expect(CoachGameReview.of(game, chessMove: 12).selected, 11);
      expect(CoachGameReview.of(game, chessMove: 0).selected, -1);
      expect(CoachGameReview.of(game, chessMove: 999).selected, 13);
    });

    test('sem os lances analisados, fica sem revisão (a engine anota)', () {
      final game = CoachGame.fromJson(
        CoachFixtures.idTiago,
        CoachFixtures.tiagoJson(status: 'analisando'),
      )!;

      final match = CoachGameReview.of(game);

      expect(match.review, isNull);
      expect(match.moves, hasLength(14));
    });
  });
}
