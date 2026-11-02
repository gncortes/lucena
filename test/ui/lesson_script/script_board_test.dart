import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/core/widgets/square_flash.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/ui/lesson_script/widgets/board_coordinates.dart';
import 'package:lucena/ui/lesson_script/widgets/script_board.dart';

void main() {
  const size = 320.0;
  testWidgets(
    'stars are real board targets and survive hidden teaching marks',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScriptBoard(
              state: const LessonScriptState(
                ready: true,
                fen: '8/8/8/8/8/8/8/R7 w - - 0 1',
                stars: ['a6', 'f6', 'f2'],
              ),
              size: size,
              settings: const BoardSettings(),
              showMarks: false,
              onMove: (_) {},
            ),
          ),
        ),
      );
      for (final square in ['a6', 'f6', 'f2']) {
        expect(find.byKey(LessonScriptKeys.star(square)), findsOneWidget);
      }
      final a6 = tester.getCenter(find.byKey(LessonScriptKeys.star('a6')));
      final f6 = tester.getCenter(find.byKey(LessonScriptKeys.star('f6')));
      final f2 = tester.getCenter(find.byKey(LessonScriptKeys.star('f2')));
      expect(f6.dx - a6.dx, 5 * size / 8);
      expect(f2.dy - f6.dy, 4 * size / 8);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Canvas error preserves the position without a red outline', (
    tester,
  ) async {
    const fen = '4k3/8/8/8/8/8/8/4K3 w - - 0 1';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScriptBoard(
            state: const LessonScriptState(
              ready: true,
              fen: fen,
              tone: ScriptTone.bad,
            ),
            size: size,
            settings: const BoardSettings(),
            canvasFeedback: true,
            onMove: (_) {},
          ),
        ),
      ),
    );
    expect(find.byKey(LessonScriptKeys.wrongLine), findsNothing);
    expect(tester.widget<ScriptBoard>(find.byType(ScriptBoard)).state.fen, fen);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('a casa tocada na fala fica por cima da marca verde', (
    tester,
  ) async {
    final flash = SquareFlash();
    addTearDown(flash.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScriptBoard(
              state: const LessonScriptState(
                ready: true,
                fen: '4k3/8/8/8/8/8/8/4K3 w - - 0 1',
                marks: ['f5', 'g5'],
              ),
              size: size,
              settings: const BoardSettings(),
              flash: flash,
              onMove: (_) {},
            ),
          ),
        ),
      ),
    );
    flash.show('f5');
    await tester.pump();
    // O chessground desenha na ordem do conjunto: o realce vem por último.
    final shapes = tester.widget<Chessboard>(find.byType(Chessboard)).shapes;
    expect(shapes.last, isA<Circle>());
    expect((shapes.last as Circle).orig, Square.f5);
    expect((shapes.last as Circle).color, isNot(ScriptShapes.green));
    expect(
      shapes.whereType<Circle>().where((c) => c.orig == Square.f5),
      hasLength(2),
    );
    flash.clear();
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

    Finder shown() => find.byKey(LessonScriptKeys.coordinates);

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
      expect(shown(), findsNothing);
      await pump(
        tester,
        const LessonScriptState(ready: true, fen: fen, touching: true),
        settings: const BoardSettings(coordinates: false),
      );
      expect(shown(), findsOneWidget);
      // Fora do toque, vale a preferência do aluno.
      await pump(
        tester,
        const LessonScriptState(ready: true, fen: fen),
        settings: const BoardSettings(coordinates: false),
      );
      expect(shown(), findsNothing);
    });

    testWidgets('coordenadas por cima das marcações: o chessground vai sem '
        'as dele e a camada fica acima do tabuleiro', (tester) async {
      await pump(
        tester,
        const LessonScriptState(
          ready: true,
          fen: fen,
          marks: ['h5'],
          orientation: Side.black,
        ),
      );
      expect(board(tester).settings.enableCoordinates, isFalse);
      final layer = tester.widget<BoardCoordinates>(shown());
      expect(layer.orientation, Side.black);
      final stack = tester.widget<Stack>(
        find.ancestor(of: shown(), matching: find.byType(Stack)).first,
      );
      expect(
        (stack.children.last as Positioned).child,
        isA<BoardCoordinates>(),
      );
      expect(tester.getRect(shown()), tester.getRect(find.byType(Chessboard)));
    });
  });

  group('crossfade', () {
    const start = '4k3/8/8/8/8/8/8/4K3 w - - 0 1';
    const other = '8/8/4k3/8/8/4K3/6P1/8 w - - 0 1';

    Widget at(LessonScriptState state) => MaterialApp(
      home: Scaffold(
        body: ScriptBoard(
          state: state,
          size: size,
          settings: const BoardSettings(),
          onMove: (_) {},
        ),
      ),
    );

    LessonScriptState scene(
      String fen,
      TransitionKind kind, {
      int id = 1,
      Side side = Side.white,
      List<String> ucis = const [],
    }) => LessonScriptState(
      ready: true,
      fen: fen,
      orientation: side,
      transition: ScriptTransition(
        id: id,
        kind: kind,
        fromFen: start,
        ucis: ucis,
      ),
    );

    double ghostOpacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byKey(LessonScriptKeys.crossfade),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;

    Chessboard board(WidgetTester tester) =>
        tester.widget<Chessboard>(find.byKey(LessonScriptKeys.board));

    testWidgets('posição nova: o antigo se dissolve sobre o novo, sem vão', (
      tester,
    ) async {
      await tester.pumpWidget(at(scene(start, TransitionKind.none, id: 0)));
      expect(find.byKey(LessonScriptKeys.crossfade), findsNothing);
      await tester.pumpWidget(at(scene(other, TransitionKind.jump)));
      await tester.pump(ScriptBoard.fade ~/ 2);
      // O novo já está embaixo, inteiro; o antigo vai pela metade.
      expect(board(tester).controller.game.fen, other);
      expect(
        tester.widget<StaticChessboard>(find.byType(StaticChessboard)).fen,
        start,
      );
      expect(ghostOpacity(tester), closeTo(0.5, 0.05));
      expect(find.byType(AnimatedRotation), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.crossfade), findsNothing);
    });

    testWidgets('troca de lado: crossfade, já com as pretas embaixo', (
      tester,
    ) async {
      await tester.pumpWidget(at(scene(start, TransitionKind.none, id: 0)));
      await tester.pumpWidget(
        at(scene(other, TransitionKind.jump, side: Side.black)),
      );
      await tester.pump(ScriptBoard.fade ~/ 2);
      expect(board(tester).orientation, Side.black);
      expect(
        tester
            .widget<StaticChessboard>(find.byType(StaticChessboard))
            .orientation,
        Side.white,
      );
      expect(ghostOpacity(tester), closeTo(0.5, 0.05));
      await tester.pumpAndSettle();
      expect(find.byKey(LessonScriptKeys.crossfade), findsNothing);
    });

    testWidgets('lance da mesma linha: a peça desliza, sem crossfade', (
      tester,
    ) async {
      await tester.pumpWidget(at(scene(start, TransitionKind.none, id: 0)));
      await tester.pumpWidget(
        at(
          scene(
            '4k3/8/8/8/8/8/3K4/8 b - - 1 1',
            TransitionKind.move,
            ucis: const ['e1d2'],
          ),
        ),
      );
      await tester.pump(ScriptBoard.fade ~/ 2);
      expect(find.byKey(LessonScriptKeys.crossfade), findsNothing);
      await tester.pump(ScriptBoard.shapesDelay);
      await tester.pumpAndSettle();
    });
  });
}
