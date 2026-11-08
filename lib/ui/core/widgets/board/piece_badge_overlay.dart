import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../motion/selo_na_peca.dart';
import '../../theme/app_colors.dart';

/// Onde fica o selo de qualidade do lance (`!!`, `??`...) sobre o tabuleiro.
///
/// O selo nasce no canto de cima à direita da casa, um pouco para fora dela.
/// Na fileira de cima ele sai por cima do tabuleiro, inteiro (há espaço
/// acima); pelos lados e por baixo é empurrado para dentro (o tabuleiro vai
/// de ponta a ponta da tela).
abstract final class PieceBadgeGeometry {
  /// Lado do selo, em fração da casa.
  static const sizeFactor = 0.48;

  static Rect rect({
    required Square square,
    required Side orientation,
    required double boardSize,
  }) {
    final cell = boardSize / 8;
    final x = orientation == Side.black ? 7 - square.file : square.file;
    final y = orientation == Side.black ? square.rank : 7 - square.rank;
    final size = cell * sizeFactor;
    final left = (x * cell + cell - size * 0.7).clamp(0.0, boardSize - size);
    final top = (y * cell - size * 0.3).clamp(-size * 0.3, boardSize - size);
    return Rect.fromLTWH(left, top, size, size);
  }
}

/// O selo de qualidade do lance, por cima do tabuleiro (empilhe sobre ele,
/// do mesmo tamanho). Não recebe toques. Desenha o [SeloNaPeca] do kit,
/// ainda sem o salto (as telas de anotação ligam o salto ao aplicar H-ANI-12).
class PieceBadgeOverlay extends StatelessWidget {
  const PieceBadgeOverlay({
    required this.square,
    required this.orientation,
    required this.size,
    required this.symbol,
    required this.color,
    super.key,
  });

  static const badgeKey = Key('pieceBadge.badge');

  final Square square;
  final Side orientation;

  /// Lado do tabuleiro.
  final double size;
  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) => SeloNaPeca(
    casa: square,
    orientacao: orientation,
    tamanho: size,
    cor: color,
    saltar: false,
    chave: badgeKey,
    child: Text(
      symbol,
      style: const TextStyle(
        color: AppColors.chessWhiteColor,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
