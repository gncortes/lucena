import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

/// O centro de uma casa (`e4`) na tela, dado o retângulo do tabuleiro visto
/// pelo lado das brancas. Usado pelos testes de widget e pelos robôs do Patrol.
Offset squareCenter(Rect board, String square) {
  final parsed = Square.fromName(square);
  final size = board.width / 8;
  return Offset(
    board.left + (parsed.file + 0.5) * size,
    board.top + (7 - parsed.rank + 0.5) * size,
  );
}

/// Onde o seletor de promoção mostra cada peça quando as brancas promovem na
/// casa [square]: dama na própria casa e, descendo, cavalo, torre e bispo.
Offset promotionChoiceCenter(Rect board, String square, Role role) {
  const order = [Role.queen, Role.knight, Role.rook, Role.bishop];
  final size = board.width / 8;
  return squareCenter(board, square) + Offset(0, order.indexOf(role) * size);
}
