import 'package:chessground/chessground.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// O aparelho da regra do centro (A8): 384x854 dp, barra de status de 24 e
/// barra de navegação de 48, densidade 1.
const centroAparelho = Size(384, 854);
const centroStatusBar = 24.0;
const centroNavBar = 48.0;

/// Põe a janela do teste no aparelho da regra do centro e volta ao padrão no
/// fim.
void setCentroAparelho(WidgetTester tester) {
  const padding = FakeViewPadding(top: centroStatusBar, bottom: centroNavBar);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = centroAparelho
    ..viewPadding = padding
    ..padding = padding;
  addTearDown(tester.view.reset);
}

/// O centro da área útil, entre o fim da barra de status e o início da barra
/// de navegação, em coordenadas da tela.
double get centroUtilY =>
    centroStatusBar +
    (centroAparelho.height - centroStatusBar - centroNavBar) / 2;

/// O retângulo do maior tabuleiro (`Chessboard` ou `StaticChessboard`) da
/// tela.
Rect maiorTabuleiro(WidgetTester tester) {
  final rects = [
    ...find.byType(Chessboard).evaluate(),
    ...find.byType(StaticChessboard).evaluate(),
  ].map((e) => tester.getRect(find.byWidget(e.widget))).toList();
  expect(rects, isNotEmpty, reason: 'nenhum tabuleiro na tela');
  rects.sort((a, b) => b.width.compareTo(a.width));
  return rects.first;
}

/// Quanto o centro do tabuleiro está fora do centro útil (dp, + = abaixo).
double foraDoCentro(WidgetTester tester) =>
    maiorTabuleiro(tester).center.dy - centroUtilY;

/// O tabuleiro com o centro no centro útil (1 dp) e de ponta a ponta.
void expectTabuleiroNoCentro(WidgetTester tester) {
  final board = maiorTabuleiro(tester);
  expect(
    board.center.dy,
    closeTo(centroUtilY, 1),
    reason: 'centro do tabuleiro ${board.center.dy} x útil $centroUtilY',
  );
  expect(board.width, closeTo(centroAparelho.width, 1), reason: '$board');
  expect(board.left, closeTo(0, 1), reason: '$board');
}
