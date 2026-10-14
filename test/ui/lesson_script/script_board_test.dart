import 'package:chessground/chessground.dart';
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

  Future<void> pumpBoard(
    WidgetTester tester,
    LessonScriptState state, {
    List<String>? squares,
    bool showMarks = true,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: ScriptBoard(
            state: state,
            size: size,
            settings: const BoardSettings(),
            showMarks: showMarks,
            onMove: (_) {},
            onSquare: squares?.add,
          ),
        ),
      ),
    ),
  );

  Set<Shape> shapes(WidgetTester tester) =>
      tester.widget<Chessboard>(find.byType(Chessboard)).shapes;

  testWidgets('toque: casa vazia e ocupada chamam onSquare', (tester) async {
    final squares = <String>[];
    await pumpBoard(
      tester,
      const LessonScriptState(
        ready: true,
        fen: '8/8/8/8/3R4/8/8/8 w - - 0 1',
        touching: true,
      ),
      squares: squares,
    );
    await tester.tapAt(at(tester, Square.e4));
    await tester.tapAt(at(tester, Square.d4));
    await tester.pump();
    expect(squares, ['e4', 'd4']);
  });

  testWidgets('sem toque, a casa tocada não chama onSquare', (tester) async {
    final squares = <String>[];
    await pumpBoard(
      tester,
      const LessonScriptState(ready: true, fen: '8/8/8/8/3R4/8/8/8 w - - 0 1'),
      squares: squares,
    );
    await tester.tapAt(at(tester, Square.e4));
    await tester.pump();
    expect(squares, isEmpty);
  });

  testWidgets('toque: acerto em verde e erro em vermelho, mesmo sem marcas', (
    tester,
  ) async {
    await pumpBoard(
      tester,
      const LessonScriptState(
        ready: true,
        fen: '8/8/8/8/8/8/8/8 w - - 0 1',
        touching: true,
        touched: ['e4'],
        touchMiss: 'a1',
      ),
      showMarks: false,
    );
    expect(shapes(tester), {
      const Circle(color: ScriptShapes.green, orig: Square.e4),
      const Circle(color: ScriptShapes.red, orig: Square.a1),
    });
  });

  testWidgets('coordinates false tira as letras e os números da borda', (
    tester,
  ) async {
    await pumpBoard(
      tester,
      const LessonScriptState(
        ready: true,
        fen: '8/8/8/8/8/8/8/8 w - - 0 1',
        coordinates: false,
      ),
    );
    expect(
      tester
          .widget<Chessboard>(find.byType(Chessboard))
          .settings
          .enableCoordinates,
      isFalse,
    );
  });
}
