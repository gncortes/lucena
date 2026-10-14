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

  group('prática de toque', () {
    const fen = '4k3/8/8/8/8/8/8/4K3 w - - 0 1';

    Future<List<String>> pump(
      WidgetTester tester,
      LessonScriptState state, {
      bool showMarks = true,
      BoardSettings settings = const BoardSettings(),
    }) async {
      final squares = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: ScriptBoard(
                state: state,
                size: size,
                settings: settings,
                showMarks: showMarks,
                onMove: (_) {},
                onSquare: squares.add,
              ),
            ),
          ),
        ),
      );
      return squares;
    }

    Chessboard board(WidgetTester tester) =>
        tester.widget<Chessboard>(find.byType(Chessboard));

    testWidgets('a casa vazia e a casa com peça chegam ao cubit', (
      tester,
    ) async {
      final squares = await pump(
        tester,
        const LessonScriptState(ready: true, fen: fen, touching: true),
      );
      await tester.tapAt(at(tester, Square.d4));
      await tester.pump();
      await tester.tapAt(at(tester, Square.e1));
      await tester.pump();
      expect(squares, ['d4', 'e1']);
    });

    testWidgets('fora do toque, o clique numa casa não chega ao cubit', (
      tester,
    ) async {
      final squares = await pump(
        tester,
        const LessonScriptState(ready: true, fen: fen),
      );
      await tester.tapAt(at(tester, Square.d4));
      await tester.pump();
      expect(squares, isEmpty);
    });

    testWidgets('acerto em verde e erro em vermelho, mesmo sem as marcas', (
      tester,
    ) async {
      await pump(
        tester,
        const LessonScriptState(
          ready: true,
          fen: fen,
          touching: true,
          touched: ['e4', 'd5'],
          touchMiss: 'a1',
        ),
        showMarks: false,
      );
      expect(board(tester).shapes, {
        Circle(color: ScriptShapes.green, orig: Square.e4),
        Circle(color: ScriptShapes.green, orig: Square.d5),
        Circle(color: ScriptShapes.red, orig: Square.a1),
      });
    });

    testWidgets('virado (pretas embaixo): o clique dá a casa certa', (
      tester,
    ) async {
      final squares = await pump(
        tester,
        const LessonScriptState(
          ready: true,
          fen: fen,
          touching: true,
          orientation: Side.black,
        ),
      );
      expect(board(tester).orientation, Side.black);
      // O canto de baixo à esquerda, com as pretas embaixo, é h8.
      await tester.tapAt(at(tester, Square.a1));
      await tester.pump();
      await tester.tapAt(at(tester, Square.e4));
      await tester.pump();
      expect(squares, ['h8', 'd5']);
    });

    testWidgets('coordenadas: escondidas quando a prática pede, mostradas '
        'durante o toque', (tester) async {
      await pump(
        tester,
        const LessonScriptState(
          ready: true,
          fen: fen,
          touching: true,
          coordinates: false,
        ),
      );
      expect(board(tester).settings.enableCoordinates, isFalse);
      await pump(
        tester,
        const LessonScriptState(ready: true, fen: fen, touching: true),
        settings: const BoardSettings(coordinates: false),
      );
      expect(board(tester).settings.enableCoordinates, isTrue);
      // Fora do toque, vale a preferência do aluno.
      await pump(
        tester,
        const LessonScriptState(ready: true, fen: fen),
        settings: const BoardSettings(coordinates: false),
      );
      expect(board(tester).settings.enableCoordinates, isFalse);
    });
  });
}
