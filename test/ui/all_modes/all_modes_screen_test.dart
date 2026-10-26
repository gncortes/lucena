import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/all_modes/widgets/all_modes_screen.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';

import '../../../testing/fakes/fake_profile_repository.dart';
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

  testWidgets('todos os modos num lugar só', (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const TestApp(locale: Locale('pt'), child: AllModesScreen()),
    );
    await tester.pumpAndSettle();
    for (final mode in [
      'stars',
      'forYou',
      'endgames',
      'journey',
      'train',
      'blind',
      'lichess',
      'speedrun',
      'freeBoard',
      'custom',
      'rating',
      'achievements',
    ]) {
      expect(find.byKey(AllModesKeys.item(mode)), findsOneWidget, reason: mode);
    }
    expect(find.text('Às cegas'), findsOneWidget);
    // A Escola escondida (VisibleLessons) não aparece.
    expect(find.byKey(AllModesKeys.item('learn')), findsNothing);
  });

  testWidgets('ordem das seções permanece igual entre níveis', (tester) async {
    tester.view.physicalSize = const Size(1080, 8000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    Future<double> top(UserProfile profile, String mode) async {
      final cubit = ProfileCubit(FakeProfileRepository(profile));
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: BlocProvider.value(
            value: cubit,
            child: const AllModesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byKey(AllModesKeys.item(mode))).dy;
    }

    const master = UserProfile(rating: 2400);
    expect(await top(master, 'stars'), lessThan(await top(master, 'journey')));
    const beginner = UserProfile(rating: 800);
    expect(
      await top(beginner, 'stars'),
      lessThan(await top(beginner, 'journey')),
    );
  });
}
