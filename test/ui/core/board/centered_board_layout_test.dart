import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/board/centered_board_layout.dart';
import 'package:lucena/ui/core/keys/board_layout_keys.dart';

/// T64: o tabuleiro com o centro no centro do espaço útil (do topo da área
/// ao rodapé), com o resto acima e abaixo sem tirá-lo do lugar.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Size screen, {
    double topHeight = 60,
    double bottomHeight = 40,
    double footerHeight = 80,
    double? centerY,
    double? minBoardSide,
    bool measureBlock = false,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: CenteredBoardLayout(
            centerY: centerY,
            minBoardSide: minBoardSide,
            balanced: measureBlock,
            measureBlock: measureBlock,
            gutter: 8,
            top: SizedBox(key: BoardLayoutKeys.top, height: topHeight),
            board: const ColoredBox(
              key: BoardLayoutKeys.board,
              color: Colors.brown,
            ),
            bottom: SizedBox(key: BoardLayoutKeys.bottom, height: bottomHeight),
            footer: SizedBox(key: BoardLayoutKeys.footer, height: footerHeight),
          ),
        ),
      ),
    );
  }

  /// O centro do espaço útil: do fim da barra do app ao topo do rodapé.
  double usefulCenter(WidgetTester tester) {
    final appBarEnd = tester.getBottomLeft(find.byType(AppBar)).dy;
    final footerTop = tester.getTopLeft(find.byKey(BoardLayoutKeys.footer)).dy;
    return (appBarEnd + footerTop) / 2;
  }

  for (final (name, screen) in [
    ('celular pequeno', const Size(360, 640)),
    ('celular grande', const Size(412, 915)),
    ('tablet deitado', const Size(1280, 800)),
  ]) {
    testWidgets('$name: tabuleiro no centro do espaço útil', (tester) async {
      await pump(tester, screen);
      final board = tester.getRect(find.byKey(BoardLayoutKeys.board));
      expect(board.center.dy, closeTo(usefulCenter(tester), 0.01));
      expect(board.center.dx, closeTo(screen.width / 2, 0.01));
      expect(board.width, board.height);
      // Em cima e embaixo, sem cobrir o tabuleiro.
      final top = tester.getRect(find.byKey(BoardLayoutKeys.top));
      final bottom = tester.getRect(find.byKey(BoardLayoutKeys.bottom));
      final footer = tester.getRect(find.byKey(BoardLayoutKeys.footer));
      expect(top.bottom, lessThanOrEqualTo(board.top));
      expect(bottom.top, greaterThanOrEqualTo(board.bottom));
      expect(bottom.bottom, lessThanOrEqualTo(footer.top));
    });
  }

  testWidgets('o que não cabe em cima encolhe e não empurra o tabuleiro', (
    tester,
  ) async {
    const screen = Size(360, 640);
    await pump(tester, screen, topHeight: 600);
    final board = tester.getRect(find.byKey(BoardLayoutKeys.board));
    expect(board.center.dy, closeTo(usefulCenter(tester), 0.01));
    final top = tester.getRect(find.byKey(BoardLayoutKeys.top));
    expect(top.height, lessThan(600));
    expect(top.bottom, lessThanOrEqualTo(board.top));
    expect(top.top, greaterThanOrEqualTo(kToolbarHeight));
    expect(tester.takeException(), isNull);
  });

  testWidgets('centro explícito inclui a barra e o rodapé sem sobreposição', (
    tester,
  ) async {
    const screen = Size(400, 800);
    await pump(tester, screen, centerY: 400 - kToolbarHeight);
    final board = tester.getRect(find.byKey(BoardLayoutKeys.board));
    final footer = tester.getRect(find.byKey(BoardLayoutKeys.footer));
    expect(board.center.dy, 400);
    expect(board.bottom, lessThanOrEqualTo(footer.top));
    await pump(tester, screen, centerY: 380 - kToolbarHeight);
    expect(tester.getCenter(find.byKey(BoardLayoutKeys.board)).dy, 380);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'altura inviável preserva o tabuleiro e permite rolar ao rodapé',
    (tester) async {
      await pump(
        tester,
        const Size(800, 360),
        topHeight: 80,
        footerHeight: 192,
        centerY: 96,
        minBoardSide: 240,
      );
      final board = tester.getRect(find.byKey(BoardLayoutKeys.board));
      expect(board.width, 240);
      expect(board.height, 240);
      expect(
        tester.getBottomLeft(find.byKey(BoardLayoutKeys.top)).dy,
        lessThanOrEqualTo(board.top),
      );
      await tester.ensureVisible(find.byKey(BoardLayoutKeys.footer));
      final footer = tester.getRect(find.byKey(BoardLayoutKeys.footer));
      expect(footer.top, greaterThanOrEqualTo(kToolbarHeight));
      expect(footer.bottom, lessThanOrEqualTo(360));
      expect(tester.takeException(), isNull);
    },
  );

  test('BoardCentering: reserva grande encolhe o tabuleiro até o mínimo', () {
    final centering = BoardCentering(
      const Size(400, 800),
      reserveTop: 1000,
      minFraction: 0.5,
    );
    expect(centering.side, centering.maxSide * 0.5);
    expect(centering.board.center.dy, 400);
    expect(centering.roomAbove, closeTo(centering.maxRoomAbove, 0.001));
  });

  for (final screen in [const Size(360, 740), const Size(412, 917)]) {
    testWidgets('T65 $screen: o bloco medido tem o mesmo vão em cima e '
        'embaixo', (tester) async {
      await pump(tester, screen, topHeight: 40, measureBlock: true);
      final appBarEnd = tester.getBottomLeft(find.byType(AppBar)).dy;
      final top = tester.getRect(find.byKey(BoardLayoutKeys.top));
      final board = tester.getRect(find.byKey(BoardLayoutKeys.board));
      final bottom = tester.getRect(find.byKey(BoardLayoutKeys.bottom));
      final footer = tester.getRect(find.byKey(BoardLayoutKeys.footer));
      expect(board.top - top.bottom, closeTo(8, 0.01));
      expect(bottom.top - board.bottom, closeTo(8, 0.01));
      expect(top.top - appBarEnd, closeTo(footer.top - bottom.bottom, 1));
      expect(board.width, screen.width);
    });
  }
}
