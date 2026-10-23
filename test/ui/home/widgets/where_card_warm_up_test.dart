import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/race/race_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/journey.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/pace_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/where_card.dart';
import 'package:lucena/ui/race/view_models/race_warm_up_cubit.dart';
import 'package:lucena/ui/race/widgets/race_warm_up_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_race_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  testWidgets('depois da partida do aquecimento, a volta cai na tela do '
      'desafio, não na Início', (tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = FakeRaceRepository(now: FakeNow(DateTime(2026)))
      ..offers = true;
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final rung = sampleLadder.first;
    final state = HomeState(
      ready: true,
      current: RungProgress(
        rung: rung,
        status: RungStatus.open,
        completed: const {},
      ),
      next: rung.challenges.first,
    );
    final position = rung.challenges.first.position.id;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: WhereCard(state: state)),
        ),
        GoRoute(
          path: Routes.journeyChallenge(rung.id, position),
          builder: (_, _) => const Scaffold(body: Text('tela do desafio')),
        ),
        GoRoute(
          path: Routes.raceWarmUp,
          builder: (context, routerState) => BlocProvider(
            create: (_) => RaceWarmUpCubit(repository)..load(),
            child: RaceWarmUpScreen(args: routerState.extra! as RaceWarmUpArgs),
          ),
        ),
        GoRoute(
          path: '/board',
          builder: (_, _) => const Scaffold(body: Text('a partida')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      RepositoryProvider<RaceRepository>.value(
        value: repository,
        child: TestApp(
          settingsCubit: settings,
          router: router,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeKeys.whereContinue));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(RaceKeys.offerWarm));
    await tester.pumpAndSettle();
    expect(find.byKey(RaceKeys.warmUpScreen), findsOneWidget);

    await tester.tap(find.byKey(RaceKeys.warmUpSkip));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(PaceKeys.confirm));
    await tester.pumpAndSettle();
    expect(find.text('a partida'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('tela do desafio'), findsOneWidget);
    expect(find.byKey(HomeKeys.whereContinue), findsNothing);
  });
}
