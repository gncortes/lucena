import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/ui/lesson_script/widgets/script_board.dart';

void main() {
  const size = 320.0;

  /// O centro da casa [square] com as brancas embaixo.
  Offset at(WidgetTester tester, Square square) {
    final origin = tester.getTopLeft(find.byType(ScriptBoard));
    const cell = size / 8;
    return origin +
        Offset((square.file + 0.5) * cell, (7 - square.rank + 0.5) * cell);
  }

  testWidgets('sem rei: o tabuleiro aceita os destinos do estado', (
    tester,
  ) async {
    final moves = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScriptBoard(
              state: LessonScriptState(
                ready: true,
                fen: '8/8/8/8/3R4/8/8/8 w - - 0 1',
                movable: Side.white,
                dests: {
                  Square.d4: {Square.d8, Square.a4},
                },
              ),
              size: size,
              settings: const BoardSettings(),
              onMove: moves.add,
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(at(tester, Square.d4));
    await tester.pump();
    await tester.tapAt(at(tester, Square.d8));
    await tester.pumpAndSettle();
    expect(moves, ['d4d8']);
  });
}
