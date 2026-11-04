import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/widgets/board/piece_badge_overlay.dart';

void main() {
  const board = 400.0;
  const square = board / 8;
  const badge = square * 0.48;

  Rect rect(Square s, {Side side = Side.white}) =>
      PieceBadgeGeometry.rect(square: s, orientation: side, boardSize: board);

  void inside(Rect r) {
    expect(r.left, greaterThanOrEqualTo(0));
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.right, lessThanOrEqualTo(board + 0.001));
    expect(r.bottom, lessThanOrEqualTo(board + 0.001));
    expect(r.width, closeTo(badge, 0.001));
  }

  test('no meio: o selo fica no canto de cima à direita da casa', () {
    final r = rect(Square.d4);
    // d4: coluna 3, fileira 4 (de cima para baixo: 7 - 3 = 4).
    expect(r.left, closeTo(3 * square + square - badge * 0.7, 0.001));
    expect(r.top, closeTo(4 * square - badge * 0.3, 0.001));
    inside(r);
  });

  test('a8 (canto de cima à esquerda): o selo não sai do tabuleiro', () {
    final r = rect(Square.a8);
    expect(r.top, 0);
    inside(r);
  });

  test('h8 (canto de cima à direita): fica dentro', () {
    final r = rect(Square.h8);
    expect(r.top, 0);
    expect(r.right, closeTo(board, 0.001));
    inside(r);
  });

  test('h1 (canto de baixo à direita): fica dentro', () {
    final r = rect(Square.h1);
    expect(r.right, closeTo(board, 0.001));
    inside(r);
  });

  test('a1 e as bordas: todas as 64 casas, nas duas orientações', () {
    for (final side in Side.values) {
      for (var i = 0; i < 64; i++) {
        inside(rect(Square(i), side: side));
      }
    }
  });

  test('8ª fileira e coluna h ficam dentro mesmo com o tabuleiro virado', () {
    for (var file = 0; file < 8; file++) {
      inside(rect(Square(56 + file), side: Side.black));
    }
    for (var rank = 0; rank < 8; rank++) {
      inside(rect(Square(rank * 8 + 7), side: Side.black));
    }
  });

  testWidgets('o widget põe o selo no retângulo calculado, sem tocar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: PieceBadgeOverlay(
            square: Square.a8,
            orientation: Side.white,
            size: board,
            symbol: '??',
            color: Colors.red,
          ),
        ),
      ),
    );
    final origin = tester.getTopLeft(find.byType(PieceBadgeOverlay));
    final badgeRect = tester.getRect(find.byKey(PieceBadgeOverlay.badgeKey));
    final expected = PieceBadgeGeometry.rect(
      square: Square.a8,
      orientation: Side.white,
      boardSize: board,
    );
    expect((badgeRect.topLeft - origin).dx, closeTo(expected.left, 0.001));
    expect((badgeRect.topLeft - origin).dy, closeTo(expected.top, 0.001));
    expect(find.text('??'), findsOneWidget);
    expect(
      tester.widget<IgnorePointer>(find.byType(IgnorePointer).first).ignoring,
      isTrue,
    );
  });
}
