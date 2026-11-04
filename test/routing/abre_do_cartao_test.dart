import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/abre_do_cartao.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/core/motion/rota_que_abre.dart';

import '../../testing/test_app.dart';

/// H-ANI-04 na entrada da aula: quem chega pelo cartão (extra
/// [AbreDoCartao]) cresce dele; o resto mantém a página de antes.
void main() {
  const cartao = ValueKey('cartão');
  final id = AbreDoCartao.daAula('escola.1');

  Future<void> monta(WidgetTester tester, Object? extra) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 860);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: OrigemQueAbre(
                id: id,
                child: GestureDetector(
                  onTap: () => context.push('/aula', extra: extra),
                  child: const SizedBox(
                    key: cartao,
                    width: 200,
                    height: 100,
                    child: Text('Cartão'),
                  ),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/aula',
          pageBuilder: (context, state) =>
              paginaQueAbre(
                context,
                state,
                const Scaffold(body: Text('aula')),
              ) ??
              MaterialPage<void>(
                key: state.pageKey,
                child: const Scaffold(body: Text('aula')),
              ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(cartao));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('pelo cartão: a aula cresce dele até a tela', (tester) async {
    await monta(tester, AbreDoCartao(id: id, lesson: 'aula'));
    await tester.pump(LucenaMotion.cartaoAbre ~/ 2);
    final meio = tester.getRect(find.byKey(MotionKeys.rotaQueAbre));
    expect(meio.width, greaterThan(200));
    expect(meio.height, lessThan(860));
    await tester.pumpAndSettle();
    expect(find.text('aula'), findsOneWidget);
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
  });

  testWidgets('sem o extra do cartão: a página de sempre', (tester) async {
    await monta(tester, 'aula');
    await tester.pump(LucenaMotion.cartaoAbre ~/ 2);
    expect(find.byKey(MotionKeys.rotaQueAbre), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('aula'), findsOneWidget);
  });

  testWidgets('a mesma lição em duas telas: fechar a de cima não apaga a '
      'origem da de baixo', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 860);
    addTearDown(tester.view.reset);
    Widget cartaoQueAbre(String rota, Key key) => Builder(
      builder: (context) => OrigemQueAbre(
        id: id,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push(rota, extra: AbreDoCartao(id: id)),
          child: SizedBox(key: key, width: 200, height: 100),
        ),
      ),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              Scaffold(body: Center(child: cartaoQueAbre('/aula', cartao))),
        ),
        GoRoute(
          path: '/capitulo',
          builder: (_, _) => Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: cartaoQueAbre('/aula', const ValueKey('linha')),
            ),
          ),
        ),
        GoRoute(
          path: '/aula',
          pageBuilder: (context, state) => paginaQueAbre(
            context,
            state,
            const Scaffold(body: Text('aula')),
          )!,
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/capitulo');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(cartao));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(MotionKeys.rotaQueAbre), findsOneWidget);
  });

  test('a lição viaja dentro do extra', () {
    expect(AbreDoCartao.licaoDe(AbreDoCartao(id: id, lesson: 'x')), 'x');
    expect(AbreDoCartao.licaoDe('y'), 'y');
  });
}
