import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/free_board/widgets/clock_row.dart';

/// A regra do bloco central das telas de jogo (Partida, Speedrun, Maratona):
/// linha do adversário + tabuleiro + linha do jogador ficam centrados entre o
/// fim da AppBar (com a lista de lances) e o topo do rodapé, a sobra dividida
/// meio a meio. Devolve o vão de cima e o de baixo, em dp.
({double above, double below}) blockGaps(WidgetTester tester, Rect board) {
  final appBarBottom = tester.getRect(find.byType(AppBar)).bottom;
  final double footerTop;
  if (find.byKey(FreeBoardKeys.actionsBar).evaluate().isNotEmpty) {
    footerTop = tester.getRect(find.byKey(FreeBoardKeys.actionsBar)).top;
  } else {
    // O rodapé do fim da partida: botão de 52 com 12 de respiro.
    footerTop =
        tester.getRect(find.byKey(FreeBoardKeys.seeResultButton)).top - 12;
  }
  var top = board.top;
  var bottom = board.bottom;
  for (final row in tester.widgetList<ClockRow>(find.byType(ClockRow))) {
    final rect = tester.getRect(find.byWidget(row));
    if (rect.top < top) top = rect.top;
    if (rect.bottom > bottom) bottom = rect.bottom;
  }
  return (above: top - appBarBottom, below: footerTop - bottom);
}

/// O vão de cima e o de baixo do bloco central são iguais (tolerância 1 dp).
void expectBalancedBlock(WidgetTester tester, Rect board) {
  final gaps = blockGaps(tester, board);
  expect(
    gaps.above,
    closeTo(gaps.below, 1),
    reason: 'vão de cima ${gaps.above} x de baixo ${gaps.below}',
  );
}
