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
    bool course = true,
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
          builder: (context, state) => NextStepsScreen(
            level: int.tryParse(state.uri.queryParameters['level'] ?? ''),
            courseAvailable: () async => course,
          ),
        ),
        GoRoute(
          path: Routes.nextStepsSchool,
          builder: (context, state) => NextStepsScreen(
            graduated: true,
            courseAvailable: () async => course,
          ),
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

  testWidgets('depois do nível: o nível, as três opções com um selo só e a '
      'linha dos dados, que abre a folha', (tester) async {
    await pump(tester, Routes.nextStepsReady(level: 1400));
    expect(find.text('Your level: 1400'), findsOneWidget);
    expect(find.text('Next steps'), findsOneWidget);
    for (final id in ['lessons', 'race', 'train']) {
      expect(find.byKey(NextStepsKeys.option(id)), findsOneWidget);
    }
    expect(find.byKey(NextStepsKeys.option('journey')), findsNothing);
    expect(find.text('Recommended'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(NextStepsKeys.resultsInfo),
      200,
      scrollable: scrollable(),
    );
    expect(
      tester.getSize(find.byKey(NextStepsKeys.resultsInfo)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byKey(NextStepsKeys.resultsInfo));
    await tester.pumpAndSettle();
    expect(find.byKey(NextStepsKeys.resultsSheet), findsOneWidget);
    expect(find.text('Your results count'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.byKey(NextStepsKeys.resultsItem(i)), findsOneWidget);
    }
    await tester.tap(find.byKey(NextStepsKeys.resultsSheetClose));
    await tester.pumpAndSettle();
    expect(find.byKey(NextStepsKeys.resultsSheet), findsNothing);
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

  testWidgets('Escola concluída: a Jornada entra, com a linha dos dados', (
    tester,
  ) async {
    await pump(tester, Routes.nextStepsSchool);
    expect(find.text('You completed the School!'), findsOneWidget);
    expect(find.text('Recommended'), findsOneWidget);
    expect(
      find.text('Start with the Opposition, the endgame that comes up most.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.byKey(NextStepsKeys.resultsInfo),
      200,
      scrollable: scrollable(),
    );
    expect(find.byKey(NextStepsKeys.option('journey')), findsOneWidget);
    await tester.tap(find.byKey(NextStepsKeys.option('journey')));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.journey);
  });

  testWidgets('sem aula liberada: o curso não é recomendado nem aparece', (
    tester,
  ) async {
    await pump(tester, Routes.nextStepsReady(level: 1800), course: false);
    expect(find.byKey(NextStepsKeys.option('lessons')), findsNothing);
    for (final id in ['race', 'train']) {
      expect(find.byKey(NextStepsKeys.option(id)), findsOneWidget);
    }
    // O único "Recomendado" passa para "Praticar finais".
    expect(find.text('Recommended'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(NextStepsKeys.option('train')),
        matching: find.text('Recommended'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(NextStepsKeys.option('train')));
    await tester.pumpAndSettle();
    expect(opened.last, Routes.catalog);
  });
}
