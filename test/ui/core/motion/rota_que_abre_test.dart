import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/rota_que_abre.dart';

import 'entrada_helpers.dart';

/// H-ANI-04 por rota: a página do go_router cresce do retângulo do cartão
/// marcado com [OrigemQueAbre] até a tela inteira, e volta no pop.
void main() {
  const cartao = ValueKey('cartão');
  const canto = Offset(40, 300);
  const tamanho = Size(200, 100);
  const tela = Size(412, 860);

  GoRouter rotas({bool venda = false}) => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: canto.dx,
                top: canto.dy,
                child: OrigemQueAbre(
                  id: 'plano',
                  child: GestureDetector(
                    onTap: () => context.push('/b'),
                    child: Container(
                      key: cartao,
                      width: tamanho.width,
                      height: tamanho.height,
                      color: Colors.teal,
                      child: const Text('Cartão'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        routes: [
          GoRoute(
            path: 'b',
            pageBuilder: (context, state) => RotaQueAbre<void>(
              context: context,
              id: 'plano',
              venda: venda,
              key: state.pageKey,
              child: const Scaffold(body: Center(child: _Contador())),
            ),
          ),
        ],
      ),
    ],
  );

  Future<GoRouter> abre(
    WidgetTester tester, {
    bool reduzir = false,
    bool venda = false,
  }) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = rotas(venda: venda);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: tela, disableAnimations: reduzir),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.byKey(cartao));
    // O go_router resolve o push no quadro seguinte; a animação começa nele.
    await tester.pump();
    await tester.pump();
    return router;
  }

  Rect quadro(WidgetTester tester) =>
      tester.getRect(find.byKey(MotionKeys.rotaQueAbre));

  testWidgets('cresce do cartão à tela em 450 ms (fastOutSlowIn)', (
    tester,
  ) async {
    await abre(tester);
    final inicio = canto & tamanho;
    expect(quadro(tester).left, closeTo(inicio.left, 1));
    expect(quadro(tester).height, closeTo(inicio.height, 1));
    // O cartão de origem fica escondido enquanto a tela está aberta.
    await tester.pump();
    expect(opacidadeAcima(tester, find.byKey(cartao).first), 0);

    await tester.pump(const Duration(milliseconds: 225));
    final p = Curves.fastOutSlowIn.transform(225 / 450);
    final meio = Rect.lerp(inicio, Offset.zero & tela, p)!;
    expect(quadro(tester).top, closeTo(meio.top, 3));
    expect(quadro(tester).width, closeTo(meio.width, 3));

    await tester.pump(const Duration(milliseconds: 226));
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
    expect(find.textContaining('Tela B'), findsOneWidget);
  });

  testWidgets('a tela aberta guarda o estado quando a abertura termina', (
    tester,
  ) async {
    await abre(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tela B 0'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Tela B 1'));
    await tester.pump();
    expect(find.text('Tela B 2'), findsOneWidget);
  });

  testWidgets('a tela aberta entra em fade entre 20% e 40%', (tester) async {
    await abre(tester);
    await tester.pump(const Duration(milliseconds: 80));
    expect(opacidadeAcima(tester, find.textContaining('Tela B')), 0);
    await tester.pump(const Duration(milliseconds: 110));
    expect(opacidadeAcima(tester, find.textContaining('Tela B')), 1);
  });

  testWidgets('voltar do sistema encolhe de volta ao cartão', (tester) async {
    await abre(tester);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final fim = quadro(tester);
    expect(fim.left, closeTo(canto.dx, 6));
    expect(fim.width, closeTo(tamanho.width, 12));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tela B'), findsNothing);
    expect(opacidadeAcima(tester, find.byKey(cartao)), 1);
  });

  testWidgets('venda: 560 ms', (tester) async {
    await abre(tester, venda: true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(MotionKeys.rotaQueAbre), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 61));
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
  });

  testWidgets('movimento reduzido: só fade de 100 ms, sem retângulo', (
    tester,
  ) async {
    await abre(tester, reduzir: true);
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      opacidadeAcima(tester, find.textContaining('Tela B')),
      inExclusiveRange(0, 1),
    );
    await tester.pump(const Duration(milliseconds: 51));
    expect(opacidadeAcima(tester, find.textContaining('Tela B')), 1);
  });

  testWidgets('sem a origem na tela: abre em fade, sem quebrar', (
    tester,
  ) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/b',
      routes: [
        GoRoute(
          path: '/b',
          pageBuilder: (context, state) => RotaQueAbre<void>(
            context: context,
            id: 'sumiu',
            key: state.pageKey,
            child: const Text('Tela B'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tela B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// Conta os toques: o número só sobrevive se a tela não for montada de novo.
class _Contador extends StatefulWidget {
  const _Contador();

  @override
  State<_Contador> createState() => _ContadorState();
}

class _ContadorState extends State<_Contador> {
  var _n = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _n++),
    child: Text('Tela B $_n'),
  );
}
