import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/halo_de_xeque.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/core/motion/tabuleiro_animado.dart';

/// H-ANI-10: a peça desliza em 300 ms, a capturada encolhe e some em 160 ms
/// quando a outra chega, e o halo do xeque pulsa duas vezes em 700 ms.
void main() {
  const antes = '4k3/8/8/1p6/P7/8/8/4K3 w - - 0 1';
  const depois = '4k3/8/8/1P6/8/8/8/4K3 b - - 0 1';
  const xeque = '4k3/8/8/8/8/8/8/4K2R w - - 0 1';
  const deuXeque = '4k2R/8/8/8/8/8/8/4K3 b - - 0 1';

  GameData jogo(String fen, {Square? xeque}) => GameData(
    fen: fen,
    playerSide: PlayerSide.none,
    sideToMove: Side.white,
    validMoves: const {},
    kingSquareInCheck: xeque,
  );

  late ChessboardController controlador;

  Widget tela({bool reduzir = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(412, 917),
        disableAnimations: reduzir,
      ),
      child: Scaffold(
        body: Builder(
          builder: (context) => TabuleiroAnimado(
            controlador: controlador,
            orientacao: Side.white,
            tamanho: 320,
            pecas: PieceSet.meridaAssets,
            child: Chessboard(
              size: 320,
              controller: controlador,
              orientation: Side.white,
              settings: TabuleiroAnimado.ajustes(
                context,
                const ChessboardSettings(),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  setUp(() => controlador = ChessboardController(game: jogo(antes)));
  tearDown(() => controlador.dispose());

  double escalaDaCapturada(WidgetTester tester) => tester
      .widget<Transform>(find.byKey(MotionKeys.pecaCapturada))
      .transform
      .storage[0];

  testWidgets('a4→b5: o tabuleiro desliza a peça em 300 ms (zero com '
      'movimento reduzido)', (tester) async {
    Duration? duracao;
    for (final reduzir in [false, true]) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduzir),
          child: Builder(
            builder: (context) {
              duracao = TabuleiroAnimado.ajustes(
                context,
                const ChessboardSettings(),
              ).animationDuration;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(duracao, reduzir ? Duration.zero : LucenaMotion.lance);
    }
    // O deslize em si é do chessground, que pinta as peças num
    // CustomPainter e guarda o progresso em membros internos.
    await tester.pumpWidget(tela());
    controlador.updatePosition(jogo(depois));
    await tester.pump();
    expect(controlador.pieces[Square.b5], Piece.whitePawn);
    await tester.pumpAndSettle();
  });

  group('capturadasNoLance', () {
    Pieces pecas(String fen) => readFen(fen);

    test('captura comum: a peça da casa tomada', () {
      expect(TabuleiroAnimado.capturadasNoLance(pecas(antes), pecas(depois)), {
        Square.b5: Piece.blackPawn,
      });
    });

    test('en passant: a peça da casa que ficou vazia', () {
      expect(
        TabuleiroAnimado.capturadasNoLance(
          pecas('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1'),
          pecas('4k3/8/3P4/8/8/8/8/4K3 b - - 0 1'),
        ),
        {Square.d5: Piece.blackPawn},
      );
    });

    test('lance sem captura e troca de posição: nada', () {
      expect(
        TabuleiroAnimado.capturadasNoLance(pecas(xeque), pecas(deuXeque)),
        isEmpty,
      );
      expect(
        TabuleiroAnimado.capturadasNoLance(
          pecas(antes),
          pecas('3qk3/8/8/8/8/8/8/3QK3 w - - 0 1'),
        ),
        isEmpty,
      );
    });
  });

  testWidgets('captura: em 380 ms a capturada encolhe, em 460 ms saiu', (
    tester,
  ) async {
    await tester.pumpWidget(tela());
    controlador.updatePosition(jogo(depois));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(escalaDaCapturada(tester), 1);
    await tester.pump(const Duration(milliseconds: 180));
    expect(escalaDaCapturada(tester), allOf(greaterThan(.55), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 80));
    expect(find.byKey(MotionKeys.pecaCapturada), findsNothing);
  });

  testWidgets('xeque: o halo está na casa do rei e pulsa duas vezes em '
      '700 ms', (tester) async {
    controlador = ChessboardController(game: jogo(xeque));
    await tester.pumpWidget(tela());
    expect(find.byKey(MotionKeys.haloDeXeque), findsNothing);
    controlador.updatePosition(jogo(deuXeque, xeque: Square.e8));
    await tester.pump();
    final halo = find.byKey(MotionKeys.haloDeXeque);
    final tabuleiro = tester.getTopLeft(find.byType(Chessboard));
    expect(tester.getTopLeft(halo) - tabuleiro, const Offset(160, 0));
    final opacidades = <double>[];
    for (var ms = 0; ms <= 700; ms += 25) {
      opacidades.add(tester.widget<Opacity>(halo).opacity);
      await tester.pump(const Duration(milliseconds: 25));
    }
    var picos = 0;
    for (var i = 1; i < opacidades.length - 1; i++) {
      if (opacidades[i] > opacidades[i - 1] &&
          opacidades[i] >= opacidades[i + 1]) {
        picos++;
      }
    }
    expect(picos, 2);
    expect(tester.widget<Opacity>(halo).opacity, HaloDeXeque.opacidadeAcesa);
  });

  testWidgets('movimento reduzido: a peça já está em b5, sem capturada, e o '
      'halo fica aceso', (tester) async {
    await tester.pumpWidget(tela(reduzir: true));
    controlador.updatePosition(jogo(depois));
    await tester.pump();
    expect(controlador.pieces[Square.b5], Piece.whitePawn);
    expect(find.byKey(MotionKeys.pecaCapturada), findsNothing);
    controlador.updatePosition(jogo(deuXeque, xeque: Square.e8));
    await tester.pump();
    final halo = find.byKey(MotionKeys.haloDeXeque);
    for (var ms = 0; ms <= 700; ms += 100) {
      expect(tester.widget<Opacity>(halo).opacity, HaloDeXeque.opacidadeAcesa);
      await tester.pump(const Duration(milliseconds: 100));
    }
  });

  testWidgets('a animação desligada nas preferências (duração zero) segue '
      'desligada', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    );
    const desligada = ChessboardSettings(animationDuration: Duration.zero);
    expect(
      TabuleiroAnimado.ajustes(context, desligada).animationDuration,
      Duration.zero,
    );
    expect(
      TabuleiroAnimado.ajustes(
        context,
        const ChessboardSettings(),
      ).animationDuration,
      LucenaMotion.lance,
    );
  });
}
