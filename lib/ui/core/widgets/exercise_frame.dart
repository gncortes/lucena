import 'package:flutter/material.dart';

import '../board/centered_board_layout.dart';
import '../board/exercise_layout.dart';
import 'viktor_sheet.dart';

/// A moldura da tela de exercício, sem view model (T70): o personagem no
/// alto, o tabuleiro centralizado pela regra do centro (a mesma conta da tela
/// de exercício, `ExerciseLayout.solvingRect`) e o rodapé embaixo.
class ExerciseFrame extends StatelessWidget {
  const ExerciseFrame({
    required this.board,
    this.character,
    this.footer,
    this.overlays,
    this.boardKey,
    this.footerReserve = ViktorSheet.peekHeight,
    super.key,
  });

  /// O tabuleiro, com o lado calculado.
  final Widget Function(BuildContext context, double size) board;

  /// Ocupa o espaço entre o topo e o tabuleiro, alinhado à base dele.
  final Widget? character;

  /// Fixo embaixo.
  final Widget? footer;

  /// Camadas extras sobre a área, dado o retângulo do tabuleiro.
  final List<Widget> Function(BuildContext context, Rect board)? overlays;
  final Key? boardKey;

  /// A altura que o rodapé reserva na conta do centro.
  final double footerReserve;

  /// Respiro entre o personagem e o tabuleiro.
  static const characterGap = 2.0;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, box) {
            final rect = ExerciseLayout.solvingRect(
              Size(box.maxWidth, box.maxHeight),
              footer: footerReserve,
              centerY: BoardViewport.centerYOf(context),
            );
            return Stack(
              children: [
                if (character != null)
                  PositionedDirectional(
                    start: 0,
                    end: 0,
                    top: 0,
                    height: (rect.top - characterGap).clamp(0, box.maxHeight),
                    child: Align(
                      alignment: AlignmentDirectional.bottomStart,
                      child: character,
                    ),
                  ),
                Positioned.fromRect(
                  rect: rect,
                  child: KeyedSubtree(
                    key: boardKey,
                    child: board(context, rect.width),
                  ),
                ),
                ...?overlays?.call(context, rect),
              ],
            );
          },
        ),
      ),
      if (footer != null)
        PositionedDirectional(start: 0, end: 0, bottom: 0, child: footer!),
    ],
  );
}
