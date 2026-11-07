import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/next_steps/widgets/next_steps_screen.dart';

import '../../../testing/test_app.dart';

void main() {
  final opened = <String>[];

  setUp(opened.clear);

  Future<void> pump(
    WidgetTester tester,
    String location, {
    Future<bool> Function()? available,
    bool settle = true,
  }) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    GoRoute stub(String path) => GoRoute(
      path: path,
      builder: (context, state) {
        opened.add(state.uri.toString());
        return const Scaffold();
      },
    );
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: Routes.nextSteps,
          builder: (context, state) =>
              NextStepsScreen(courseAvailable: available ?? () async => true),
        ),
        stub(Routes.home),
        stub(Routes.pilaresSale),
        stub(Routes.race),
        stub(Routes.journey),
        stub(Routes.catalog),
      ],
    );
    await tester.pumpWidget(
      TestApp(router: router, child: const SizedBox.shrink()),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('com lição liberada: quatro cartões, o Pilares primeiro e com '
      'o único "Recomendado"; nenhum cita o Curso de finais', (tester) async {
    await pump(tester, Routes.nextStepsReady(level: 1400));
    expect(find.text('Next steps'), findsOneWidget);
    for (final id in ['pilares', 'race', 'train', 'journey']) {
      expect(find.byKey(NextStepsKeys.option(id)), findsOneWidget);
    }
    expect(find.text('Recommended'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(NextStepsKeys.option('pilares')),
        matching: find.text('Recommended'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(NextStepsKeys.option('pilares'))).dy,
      lessThan(tester.getTopLeft(find.byKey(NextStepsKeys.option('race'))).dy),
    );
    expect(find.textContaining('Endgame course'), findsNothing);
  });

  testWidgets('cada cartão leva ao seu destino', (tester) async {
    for (final (id, route) in [
      ('pilares', Routes.pilaresSale),
      ('race', Routes.race),
      ('train', Routes.catalog),
      ('journey', Routes.journey),
    ]) {
      await pump(tester, Routes.nextSteps);
      await tester.tap(find.byKey(NextStepsKeys.option(id)));
      await tester.pumpAndSettle();
      expect(opened.last, route, reason: id);
    }
  });

  testWidgets('"Ir para o início" e o voltar da barra levam ao Início', (
    tester,
  ) async {
    await pump(tester, Routes.nextStepsReady());
    await tester.tap(find.byKey(NextStepsKeys.home));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.home);
    await pump(tester, Routes.nextStepsReady());
    await tester.tap(find.byKey(NextStepsKeys.back));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.home);
  });

  testWidgets('carregando: quatro blocos em esqueleto, sem a lista, e '
      '"Ir para o início" visível', (tester) async {
    final gate = Completer<bool>();
    await pump(
      tester,
      Routes.nextStepsReady(),
      available: () => gate.future,
      settle: false,
    );
    expect(find.byKey(NextStepsKeys.loading), findsOneWidget);
    expect(find.byKey(NextStepsKeys.block), findsNothing);
    expect(find.byKey(NextStepsKeys.home), findsOneWidget);
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(NextStepsKeys.loading), findsNothing);
    expect(find.byKey(NextStepsKeys.option('pilares')), findsOneWidget);
  });

  testWidgets('sem lição liberada ou com a leitura falhando: três cartões, '
      'sem o Pilares e sem tela de erro', (tester) async {
    for (final available in [
      () async => false,
      () async => throw StateError('falhou'),
    ]) {
      await pump(tester, Routes.nextStepsReady(), available: available);
      expect(find.byKey(NextStepsKeys.option('pilares')), findsNothing);
      for (final id in ['race', 'train', 'journey']) {
        expect(find.byKey(NextStepsKeys.option(id)), findsOneWidget);
      }
      expect(find.text('Recommended'), findsNothing);
    }
  });
}
