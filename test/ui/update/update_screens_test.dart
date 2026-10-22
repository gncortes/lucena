import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/update/app_update_repository.dart';
import 'package:lucena/routing/router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/routing/stream_refresh.dart';
import 'package:lucena/ui/core/keys/update_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';
import 'package:lucena/ui/update/view_models/update_cubit.dart';
import 'package:lucena/ui/update/widgets/update_bridge.dart';
import 'package:lucena/ui/update/widgets/update_recommended_screen.dart';
import 'package:lucena/ui/update/widgets/update_required_screen.dart';

import '../../../testing/fakes/fake_app_update_repository.dart';
import '../../../testing/fakes/fake_remote_flags_repository.dart';

const _game = '/game';
const _homeKey = Key('test.home');
const _gameKey = Key('test.game');

void main() {
  late FakeRemoteFlagsRepository flags;
  late FakeAppUpdateRepository updates;
  late UpdateCubit cubit;

  setUp(() {
    flags = FakeRemoteFlagsRepository();
    updates = FakeAppUpdateRepository(
      info: const PlayUpdateInfo(available: true, flexibleAllowed: true),
    );
    cubit = UpdateCubit(flags: flags, updates: updates);
  });

  tearDown(() => cubit.close());

  // O mesmo redirect e o mesmo UpdateBridge do app, com duas telas falsas
  // no lugar da home e da partida.
  Future<GoRouter> pumpApp(WidgetTester tester, {String initial = '/'}) async {
    final refresh = StreamRefresh(
      cubit.stream.map((state) => state.required).distinct(),
    );
    addTearDown(refresh.dispose);
    final router = GoRouter(
      initialLocation: initial,
      refreshListenable: refresh,
      redirect: (context, state) => updateRedirect(
        state.matchedLocation,
        required: () => cubit.state.required,
      ),
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Scaffold(key: _homeKey),
        ),
        GoRoute(
          path: _game,
          builder: (context, state) => const Scaffold(key: _gameKey),
        ),
        GoRoute(
          path: Routes.updateRequired,
          builder: (context, state) => const UpdateRequiredScreen(),
        ),
        GoRoute(
          path: Routes.updateRecommended,
          builder: (context, state) => const UpdateRecommendedScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      BlocProvider<UpdateCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          theme: AppTheme.of(Brightness.light),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          routerConfig: router,
          builder: (context, child) => UpdateBridge(
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('obrigatória', () {
    testWidgets('fica por cima de tudo e não tem voltar', (tester) async {
      flags.updateMinBuild = 101;
      final router = await pumpApp(tester, initial: _game);
      await tester.runAsync(cubit.start);
      await tester.pumpAndSettle();

      expect(find.byKey(UpdateKeys.requiredScreen), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(
        find.ancestor(
          of: find.byKey(UpdateKeys.requiredScreen),
          matching: find.byWidgetPredicate(
            (widget) => widget is PopScope && !widget.canPop,
          ),
        ),
        findsOneWidget,
      );

      // Nem navegando sai dela.
      router.go(_game);
      await tester.pumpAndSettle();
      expect(find.byKey(UpdateKeys.requiredScreen), findsOneWidget);

      await tester.tap(find.byKey(UpdateKeys.requiredAction));
      expect(updates.storeOpens, 1);
    });

    testWidgets('a mínima volta a 0 e solta a home', (tester) async {
      flags.updateMinBuild = 101;
      await pumpApp(tester);
      await tester.runAsync(cubit.start);
      await tester.pumpAndSettle();
      expect(find.byKey(UpdateKeys.requiredScreen), findsOneWidget);

      flags.updateMinBuild = 0;
      await tester.runAsync(cubit.check);
      await tester.pumpAndSettle();

      expect(find.byKey(_homeKey), findsOneWidget);
    });
  });

  group('recomendada', () {
    testWidgets('não abre em partida, aula ou exercício', (tester) async {
      flags.updateRecommendedBuild = 110;
      final router = await pumpApp(tester, initial: _game);
      await tester.runAsync(cubit.start);
      await tester.pumpAndSettle();

      expect(cubit.state.decision.name, 'recommended');
      expect(find.byKey(UpdateKeys.recommendedScreen), findsNothing);
      expect(updates.seen, 0);

      // De volta à home, aparece.
      router.go(Routes.home);
      await tester.pumpAndSettle();
      expect(find.byKey(UpdateKeys.recommendedScreen), findsOneWidget);
      expect(updates.seen, 110);
    });

    testWidgets('fecha com "Agora não" e não volta', (tester) async {
      flags.updateRecommendedBuild = 110;
      await pumpApp(tester);
      await tester.runAsync(cubit.start);
      await tester.pumpAndSettle();
      expect(find.byKey(UpdateKeys.recommendedScreen), findsOneWidget);

      await tester.tap(find.byKey(UpdateKeys.recommendedLater));
      await tester.pumpAndSettle();

      expect(find.byKey(UpdateKeys.recommendedScreen), findsNothing);
      expect(find.byKey(_homeKey), findsOneWidget);
      await tester.runAsync(cubit.check);
      await tester.pumpAndSettle();
      expect(find.byKey(UpdateKeys.recommendedScreen), findsNothing);
    });

    testWidgets('Atualizar vira "Pronto. Reiniciar o Lucena"', (tester) async {
      flags.updateRecommendedBuild = 110;
      await pumpApp(tester);
      await tester.runAsync(cubit.start);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(UpdateKeys.recommendedAction));
      await tester.pumpAndSettle();
      expect(find.text('Pronto. Reiniciar o Lucena'), findsOneWidget);

      await tester.tap(find.byKey(UpdateKeys.restart));
      expect(updates.completes, 1);
    });
  });

  test('o redirect só prende quem está abaixo da mínima', () {
    expect(updateRedirect(_game), isNull);
    expect(updateRedirect(_game, required: () => true), Routes.updateRequired);
    expect(updateRedirect(Routes.updateRequired, required: () => true), isNull);
    expect(
      updateRedirect(Routes.updateRequired, required: () => false),
      Routes.home,
    );
  });
}
