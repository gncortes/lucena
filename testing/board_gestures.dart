import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

/// O centro de uma casa (`e4`) na tela, dado o retângulo do tabuleiro e o lado
/// que está embaixo. Usado pelos testes de widget e pelos robôs do Patrol.
Offset squareCenter(
  Rect board,
  String square, {
  Side orientation = Side.white,
}) {
  final parsed = Square.fromName(square);
  final size = board.width / 8;
  final column = orientation == Side.white ? parsed.file : 7 - parsed.file;
  final row = orientation == Side.white ? 7 - parsed.rank : parsed.rank;
  return Offset(
    board.left + (column + 0.5) * size,
    board.top + (row + 0.5) * size,
  );
}

/// Onde o seletor de promoção mostra cada peça quando as brancas promovem na
/// casa [square]: dama na própria casa e, descendo, cavalo, torre e bispo.
Offset promotionChoiceCenter(Rect board, String square, Role role) {
  const order = [Role.queen, Role.knight, Role.rook, Role.bishop];
  final size = board.width / 8;
  return squareCenter(board, square) + Offset(0, order.indexOf(role) * size);
}
