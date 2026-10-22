import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/account/widgets/account_screen.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';

import '../../../testing/test_app.dart';

void main() {
  Future<void> pumpAccount(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: Routes.home, builder: (_, _) => const AccountScreen()),
        GoRoute(
          path: Routes.level,
          builder: (_, _) => const Scaffold(body: Text('rota-nivel')),
        ),
      ],
    );
    await tester.pumpWidget(TestApp(router: router, child: const SizedBox()));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o convite, o que se ganha e que é opcional', (
    tester,
  ) async {
    await pumpAccount(tester);
    expect(find.text('Want to keep your progress?'), findsOneWidget);
    expect(find.textContaining('optional'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    expect(find.byIcon(Icons.devices_other), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
  });

  testWidgets('Google e e-mail avisam que o login vem aí e ficam na tela', (
    tester,
  ) async {
    await pumpAccount(tester);
    await tester.tap(find.byKey(AccountKeys.google));
    await tester.pump();
    expect(find.text('Signing in is coming soon.'), findsOneWidget);
    expect(find.byKey(AccountKeys.screen), findsOneWidget);
  });

  for (final key in [AccountKeys.later, AccountKeys.close]) {
    testWidgets('${key.toString()} segue para o nível', (tester) async {
      await pumpAccount(tester);
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(find.text('rota-nivel'), findsOneWidget);
    });
  }
}
