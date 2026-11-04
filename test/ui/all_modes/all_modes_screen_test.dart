import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/all_modes/widgets/all_modes_screen.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/core/motion/rota_que_abre.dart';

import '../../../testing/test_app.dart';

void main() {
  testWidgets('voltar de ferramenta mantém hub e rolagem de origem', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AllModesScreen()),
        GoRoute(
          path: '/custom',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('voltar'),
            ),
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
    final item = find.byKey(AllModesKeys.item('custom'));
    await tester.scrollUntilVisible(item, 300);
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(item).dy;
    await tester.tap(item);
    await tester.pumpAndSettle();
    expect(find.text('voltar'), findsOneWidget);
    await tester.tap(find.text('voltar'));
    await tester.pumpAndSettle();
    expect(find.byKey(AllModesKeys.screen), findsOneWidget);
    expect(tester.getTopLeft(item).dy, closeTo(before, 1));
  });
  for (final checkpoint in [false, true]) {
    testWidgets(
      'blind entry resumes only when checkpoint exists ($checkpoint)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 8000);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) =>
                  AllModesScreen(hasBlindCheckpoint: () async => checkpoint),
            ),
            GoRoute(
              path: '/blind',
              builder: (context, state) =>
                  const Scaffold(body: Text('resume blind')),
            ),
            GoRoute(
              path: '/blind-entry',
              builder: (context, state) => Scaffold(
                body: Text(
                  state.uri.queryParameters['resume'] == '1'
                      ? 'resume blind'
                      : 'new blind',
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          TestApp(router: router, child: const SizedBox.shrink()),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(AllModesKeys.item('blind')));
        await tester.pumpAndSettle();
        expect(
          find.text(checkpoint ? 'resume blind' : 'new blind'),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('H-PAR-01: as linhas do quadro, na ordem, com título e '
      'subtítulo', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const TestApp(locale: Locale('pt'), child: AllModesScreen()),
    );
    await tester.pumpAndSettle();

    const rows = [
      (
        'pilares',
        'Pilares do Xadrez',
        'Seu guia de treino, feito para o seu jogo',
      ),
      ('stars', 'Desafios das estrelas', 'Cada peça contra o relógio'),
      ('journey', 'Jornada', 'Do Coco ao Stockfish'),
      ('train', 'Treinar finais', 'Qualquer final, quantas vezes quiser'),
      ('speedrun', 'Speedrun', 'Uma série no relógio'),
      ('race', 'Problemas', 'Corrida de finais: 3 minutos, 3 erros'),
      ('blind', 'Às cegas', 'Sem ver as peças'),
      ('freeBoard', 'Tabuleiro livre', 'Jogue qualquer posição'),
      ('custom', 'Montar posição', 'Monte a posição peça por peça'),
    ];
    var previous = -1.0;
    for (final (id, title, body) in rows) {
      final item = find.byKey(AllModesKeys.item(id));
      expect(item, findsOneWidget, reason: id);
      expect(
        find.descendant(of: item, matching: find.text(title)),
        findsOneWidget,
        reason: id,
      );
      expect(
        find.descendant(of: item, matching: find.text(body)),
        findsOneWidget,
        reason: id,
      );
      final top = tester.getTopLeft(item).dy;
      expect(top, greaterThan(previous), reason: id);
      previous = top;
    }
    for (final section in ['Aprender', 'Jogar', 'Ferramentas']) {
      expect(find.text(section), findsOneWidget, reason: section);
    }
    // O que saiu: o progresso e o convite do Lichess.
    expect(find.text('Progresso'), findsNothing);
    for (final gone in ['rating', 'achievements', 'lichess']) {
      expect(find.byKey(AllModesKeys.item(gone)), findsNothing, reason: gone);
    }
  });

  testWidgets('H-PAR-01: a barra de cima só tem o título', (tester) async {
    await tester.pumpWidget(
      const TestApp(locale: Locale('pt'), child: AllModesScreen()),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Todos os modos'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('H-PAR-01: "Escolher os modos da home" fica fixo embaixo e abre '
      'a tela inicial', (tester) async {
    tester.view.physicalSize = const Size(393, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AllModesScreen()),
        GoRoute(
          path: Routes.homeLayout,
          builder: (_, _) => const Scaffold(body: Text('layout da home')),
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
    final button = find.byKey(AllModesKeys.chooseHome);
    expect(button, findsOneWidget);
    expect(find.text('Escolher os modos da home'), findsOneWidget);
    expect(find.byIcon(Icons.tune), findsOneWidget);
    final before = tester.getTopLeft(button).dy;
    // A lista rola e o botão não sai do lugar.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(button).dy, before);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('layout da home'), findsOneWidget);
  });

  testWidgets('H-PAR-01: Pilares abre a venda', (tester) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AllModesScreen()),
        GoRoute(
          path: Routes.pilaresSale,
          builder: (_, _) => const Scaffold(body: Text('venda')),
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
    await tester.tap(find.byKey(AllModesKeys.item('pilares')));
    await tester.pumpAndSettle();
    expect(find.text('venda'), findsOneWidget);
  });

  testWidgets('H-ANI-04: a venda cresce do cartão Pilares (entrada única)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const AllModesScreen()),
        GoRoute(
          path: Routes.pilaresSale,
          pageBuilder: (context, state) => RotaQueAbre<void>(
            context: context,
            id: 'venda',
            venda: true,
            key: state.pageKey,
            child: const Scaffold(body: Text('venda')),
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
    final cartao = tester.getRect(find.byKey(AllModesKeys.item('pilares')));
    await tester.tap(find.byKey(AllModesKeys.item('pilares')));
    await tester.pump();
    await tester.pump();
    await tester.pump(LucenaMotion.cartaoDaVenda ~/ 2);
    final meio = tester.getRect(find.byKey(MotionKeys.rotaQueAbre));
    expect(meio.width * meio.height, greaterThan(cartao.width * cartao.height));
    expect(meio.height, lessThan(873));
    await tester.pumpAndSettle();
    expect(find.text('venda'), findsOneWidget);
  });
}
