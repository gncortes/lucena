import 'package:chessground/chessground.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Um aparelho da regra do centro (A8): tamanho em dp (densidade 1) e as
/// barras de status e de navegação.
class AparelhoA8 {
  const AparelhoA8(this.size, {this.status = 24, this.nav = 32});

  final Size size;
  final double status, nav;

  /// O centro da área útil, entre o fim da barra de status e o início da
  /// barra de navegação, em coordenadas da tela.
  double get centroUtilY => status + (size.height - status - nav) / 2;

  @override
  String toString() =>
      '${size.width.toInt()}x${size.height.toInt()}, barras '
      '${status.toInt()}/${nav.toInt()}';
}

/// O aparelho de referência da regra do centro: 384x854, status 24, nav 48.
const centroAparelho = Size(384, 854);
const centroStatusBar = 24.0;
const centroNavBar = 48.0;

/// Os aparelhos em que todo teste de geometria A8 roda ([testWidgetsA8]).
/// O teste-guarda (`test/ui/core/board/centro_em_toda_tela_test.dart`) exige
/// pelo menos 360x740, 393x873 e 412x915 com barras 24/32.
const aparelhosA8 = [
  AparelhoA8(Size(360, 740)),
  AparelhoA8(centroAparelho, status: centroStatusBar, nav: centroNavBar),
  AparelhoA8(Size(393, 873)),
  AparelhoA8(Size(412, 915)),
];

AparelhoA8 _atual = aparelhosA8[1];

/// O aparelho do teste A8 em andamento (o de referência fora de
/// [testWidgetsA8]).
AparelhoA8 get aparelhoA8 => _atual;

/// A tela baixa da lista, em que algumas telas ainda não cabem com o
/// tabuleiro no centro (dívida da A8, listada no teste-guarda).
const aparelhoBaixoA8 = AparelhoA8(Size(360, 740));

/// Roda [body] uma vez em cada um dos [aparelhosA8]. Dentro dele,
/// [setCentroAparelho], [centroUtilY] e [expectTabuleiroNoCentro] usam o
/// aparelho da vez ([aparelhoA8]).
///
/// [pendente360x740]: a tela ainda não cabe em 360x740 com o tabuleiro no
/// centro e roda só nos outros. Só vale para as telas da dívida listada no
/// teste-guarda (`test/ui/core/board/centro_em_toda_tela_test.dart`).
void testWidgetsA8(
  String description,
  Future<void> Function(WidgetTester tester) body, {
  bool pendente360x740 = false,
}) {
  for (final aparelho in aparelhosA8) {
    if (pendente360x740 && aparelho.size == aparelhoBaixoA8.size) continue;
    testWidgets('$description ($aparelho)', (tester) async {
      _atual = aparelho;
      try {
        await body(tester);
      } finally {
        _atual = aparelhosA8[1];
      }
    });
  }
}

/// Põe a janela do teste no aparelho da vez e volta ao padrão no fim.
void setCentroAparelho(WidgetTester tester) {
  final padding = FakeViewPadding(top: _atual.status, bottom: _atual.nav);
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = _atual.size
    ..viewPadding = padding
    ..padding = padding;
  addTearDown(tester.view.reset);
}

/// O centro da área útil do aparelho da vez, em coordenadas da tela.
double get centroUtilY => _atual.centroUtilY;

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

/// A checagem comum da A8: o centro do tabuleiro no centro útil (±1 dp) e a
/// largura igual à da tela, de ponta a ponta.
void expectTabuleiroNoCentro(WidgetTester tester) {
  final board = maiorTabuleiro(tester);
  expect(
    board.center.dy,
    closeTo(centroUtilY, 1),
    reason:
        '$_atual: centro do tabuleiro ${board.center.dy} x útil '
        '$centroUtilY',
  );
  expect(board.width, closeTo(_atual.size.width, 1), reason: '$_atual: $board');
  expect(board.left, closeTo(0, 1), reason: '$_atual: $board');
}
