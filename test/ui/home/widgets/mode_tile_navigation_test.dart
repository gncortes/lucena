import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/home_shortcut.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/widgets/mode_tile.dart';

import '../../../../testing/test_app.dart';

void main() {
  testWidgets('School shortcut opens the course instead of board controls', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: Routes.home,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) =>
              const Scaffold(body: ModeTile(shortcut: HomeShortcut.school)),
        ),
        GoRoute(
          path: Routes.school,
          builder: (_, _) => const Scaffold(body: Text('School destination')),
        ),
        GoRoute(
          path: Routes.boardControls,
          builder: (_, _) => const Scaffold(body: Text('Board controls')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeKeys.schoolButton));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, Routes.school);
    expect(find.text('School destination'), findsOneWidget);
    expect(find.text('Board controls'), findsNothing);
  });

  for (final (hasPlan, destination) in [
    (false, Routes.pilaresSale),
    (true, Routes.training('pilares')),
  ]) {
    testWidgets(
      'Pilares do Xadrez ${hasPlan ? 'com plano abre o plano' : 'sem plano '
                'abre a venda'}',
      (tester) async {
        final router = GoRouter(
          initialLocation: Routes.home,
          routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, _) => Scaffold(
                body: ModeTile(
                  shortcut: HomeShortcut.pillars,
                  hasPlan: hasPlan,
                ),
              ),
            ),
            GoRoute(
              path: destination,
              builder: (_, _) => const Scaffold(body: Text('Destino')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            router: router,
            child: const SizedBox(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Pilares do Xadrez'), findsOneWidget);
        await tester.tap(find.byKey(HomeKeys.pillarsButton));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, destination);
      },
    );
  }
}
