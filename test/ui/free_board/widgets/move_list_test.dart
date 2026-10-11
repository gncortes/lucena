import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/free_board/widgets/move_list.dart';

void main() {
  testWidgets('com poucos lances, a faixa começa na esquerda, mesmo dentro '
      'da barra do app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(MoveList.height),
              child: MoveList(
                moves: ['Qg7', 'Kd3'],
                firstMoveNumber: 1,
                firstSide: Side.white,
              ),
            ),
          ),
        ),
      ),
    );
    final strip = tester.getRect(find.byKey(FreeBoardKeys.moveList));
    final screen = tester.getRect(find.byType(Scaffold));
    expect(strip.width, screen.width);
    expect(
      tester.getRect(find.byKey(FreeBoardKeys.move(0))).left,
      lessThan(80),
    );
  });
}
