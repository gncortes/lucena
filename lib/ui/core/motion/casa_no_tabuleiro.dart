import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';

/// O retângulo da [casa] num tabuleiro de lado [tamanho], visto do lado
/// [orientacao] (o lado de baixo).
Rect retanguloDaCasa(Square casa, Side orientacao, double tamanho) {
  final lado = tamanho / 8;
  final x = orientacao == Side.black ? 7 - casa.file : casa.file;
  final y = orientacao == Side.black ? casa.rank : 7 - casa.rank;
  return Rect.fromLTWH(x * lado, y * lado, lado, lado);
}
