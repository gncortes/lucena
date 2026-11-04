import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/ui/core/motion/transicao_eixo_x.dart';

import 'entrada_helpers.dart';

/// H-ANI-03 nas rotas (os passos da Conta): a tela nova entra pela direita e
/// a de baixo sai pela esquerda; no voltar, ao contrário.
void main() {
  GoRouter rotas() => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => PaginaEixoX<void>(
          context: context,
          key: state.pageKey,
          child: const Scaffold(body: Center(child: Text('Passo 1'))),
        ),
        routes: [
          GoRoute(
            path: 'dois',
            pageBuilder: (context, state) => PaginaEixoX<void>(
              context: context,
              key: state.pageKey,
              child: const Scaffold(body: Center(child: Text('Passo 2'))),
            ),
          ),
        ],
      ),
    ],
  );

  Future<GoRouter> abre(WidgetTester tester, {bool reduzir = false}) async {
    tester.view.physicalSize = const Size(412, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = rotas();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 800),
          disableAnimations: reduzir,
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  double dx(WidgetTester tester, int passo) =>
      tester.getCenter(find.text('Passo $passo')).dx - 206;

  testWidgets('avançar: o passo 2 vem da direita e chega em 300 ms', (
    tester,
  ) async {
    final router = await abre(tester);
    router.push('/dois');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(dx(tester, 2), greaterThan(0));
    expect(opacidadeAcima(tester, find.text('Passo 2')), lessThan(1));
    expect(dx(tester, 1), lessThanOrEqualTo(0));
    await tester.pump(const Duration(milliseconds: 160));
    expect(dx(tester, 2), 0);
    expect(opacidadeAcima(tester, find.text('Passo 2')), 1);
  });

  testWidgets('voltar: o passo 1 vem da esquerda', (tester) async {
    final router = await abre(tester);
    router.push('/dois');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(dx(tester, 1), lessThan(0));
    await tester.pumpAndSettle();
    expect(find.text('Passo 2'), findsNothing);
  });

  testWidgets('movimento reduzido: só fade, sem deslocamento', (tester) async {
    final router = await abre(tester, reduzir: true);
    router.push('/dois');
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 25));
      expect(dx(tester, 2), 0);
    }
    await tester.pumpAndSettle();
    expect(find.text('Passo 2'), findsOneWidget);
  });
}
