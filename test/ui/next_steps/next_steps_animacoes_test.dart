import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/next_steps_keys.dart';
import 'package:lucena/ui/next_steps/widgets/next_steps_screen.dart';

import '../../../testing/test_app.dart';
import '../core/motion/entrada_helpers.dart';

/// Movimento dos próximos passos (H-ANI-07 e 16): o esqueleto se dissolve e
/// os cartões entram em cascata, um depois do outro.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Future<bool> Function() available,
  ) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              NextStepsScreen(courseAvailable: available),
        ),
        GoRoute(path: Routes.home, builder: (_, _) => const Scaffold()),
      ],
    );
    await tester.pumpWidget(
      TestApp(router: router, child: const SizedBox.shrink()),
    );
  }

  testWidgets('o esqueleto e a lista coexistem e depois só a lista fica', (
    tester,
  ) async {
    final porta = Completer<bool>();
    await pump(tester, () => porta.future);
    await tester.pump();
    expect(find.byKey(NextStepsKeys.loading), findsOneWidget);

    porta.complete(true);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
    expect(find.byKey(MotionKeys.shimmerConteudo), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('os cartões sobem em cascata: o primeiro antes do último', (
    tester,
  ) async {
    await pump(tester, () async => true);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final primeiro = find.byKey(MotionKeys.itemDaCascata(0));
    final ultimo = find.byKey(MotionKeys.itemDaCascata(3));
    expect(primeiro, findsOneWidget);
    expect(opacidade(tester, primeiro), greaterThan(opacidade(tester, ultimo)));
    await tester.pumpAndSettle();
    expect(opacidade(tester, ultimo), 1);
  });
}
