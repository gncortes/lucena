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

  Future<void> pump(WidgetTester tester, String location) async {
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
          builder: (context, state) => NextStepsScreen(
            level: int.tryParse(state.uri.queryParameters['level'] ?? ''),
          ),
        ),
        GoRoute(
          path: Routes.nextStepsSchool,
          builder: (context, state) => const NextStepsScreen(graduated: true),
        ),
        stub(Routes.home),
        stub(Routes.endgames),
        stub(Routes.race),
        stub(Routes.journey),
        stub(Routes.catalog),
      ],
    );
    await tester.pumpWidget(
      TestApp(router: router, child: const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
  }

  Finder scrollable() => find
      .descendant(
        of: find.byKey(NextStepsKeys.screen),
        matching: find.byType(Scrollable),
      )
      .first;

  testWidgets('depois do nível: o nível, as três opções, o "Em breve" e a '
      'nota dos dados', (tester) async {
    await pump(tester, Routes.nextStepsReady(level: 1400));
    expect(find.text('Your level: 1400'), findsOneWidget);
    for (final id in ['lessons', 'race', 'train']) {
      expect(find.byKey(NextStepsKeys.option(id)), findsOneWidget);
    }
    expect(find.byKey(NextStepsKeys.option('journey')), findsNothing);
    expect(find.text('For you'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(NextStepsKeys.dataNote),
      200,
      scrollable: scrollable(),
    );
    expect(find.byKey(NextStepsKeys.comingSoon), findsOneWidget);
    await tester.tap(find.byKey(NextStepsKeys.home));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.home);
  });

  testWidgets('sem nível ("Não sei jogar"): o título é "Tudo pronto"', (
    tester,
  ) async {
    await pump(tester, Routes.nextStepsReady());
    expect(find.text('All set'), findsNWidgets(2));
    await tester.tap(find.byKey(NextStepsKeys.option('race')));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.race);
  });

  testWidgets('Escola concluída: a Jornada entra, sem a nota dos dados', (
    tester,
  ) async {
    await pump(tester, Routes.nextStepsSchool);
    expect(find.text('You completed the School!'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(NextStepsKeys.comingSoon),
      200,
      scrollable: scrollable(),
    );
    expect(find.byKey(NextStepsKeys.option('journey')), findsOneWidget);
    expect(find.byKey(NextStepsKeys.dataNote), findsNothing);
    await tester.tap(find.byKey(NextStepsKeys.option('journey')));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.journey);
  });
}
