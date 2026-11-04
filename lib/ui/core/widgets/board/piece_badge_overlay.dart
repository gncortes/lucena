import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Onde fica o selo de qualidade do lance (`!!`, `??`...) sobre o tabuleiro.
///
/// O selo nasce no canto de cima à direita da casa, mas nunca sai do
/// tabuleiro: em a8, h8, h1, na coluna h e na 1ª e 8ª fileiras ele é
/// empurrado para dentro.
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
    final top = (y * cell - size * 0.3).clamp(0.0, boardSize - size);
    return Rect.fromLTWH(left, top, size, size);
  }
}

/// O selo de qualidade do lance, por cima do tabuleiro (empilhe sobre ele,
/// do mesmo tamanho). Não recebe toques.
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
  Widget build(BuildContext context) {
    final r = PieceBadgeGeometry.rect(
      square: square,
      orientation: orientation,
      boardSize: size,
    );
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: r,
              child: Container(
                key: badgeKey,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.trainingFabShadow,
                      blurRadius: 1,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: FittedBox(
                  child: Text(
                    symbol,
                    style: const TextStyle(
                      color: AppColors.chessWhiteColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
