import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';
import 'package:lucena/ui/core/keys/catalog_keys.dart';
import 'package:lucena/ui/core/keys/game_setup_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/game_setup/view_models/game_setup_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_dependencies.dart';

void main() {
  testWidgets(
    'hub → às cegas → catálogo → posição conserva intenção e origem',
    (tester) async {
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        LucenaApp(
          dependencies: testDependencies(
            settingsRepository: FakeSettingsRepository(
              const AppSettings(languageCode: 'pt'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
      router.push(Routes.allModes);
      await tester.pumpAndSettle();
      final blind = find.byKey(AllModesKeys.item('blind'));
      await tester.scrollUntilVisible(blind, 250);
      await tester.pumpAndSettle();
      final origin = tester.getTopLeft(blind).dy;
      await tester.tap(blind);
      await tester.pumpAndSettle();
      expect(find.byKey(CatalogKeys.screen), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.byKey(CatalogKeys.screen)))
            .uri
            .queryParameters['blind'],
        '1',
      );
      await tester.tap(find.byKey(CatalogKeys.category('basic')));
      await tester.pumpAndSettle();
      expect(find.byKey(CatalogKeys.categoryScreen), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.byKey(CatalogKeys.categoryScreen)))
            .uri
            .queryParameters['blind'],
        '1',
      );
      await tester.tap(find.byKey(CatalogKeys.position('basic.queen.0001')));
      await tester.pumpAndSettle();
      expect(find.byKey(GameSetupKeys.screen), findsOneWidget);
      expect(
        tester
            .element(find.byKey(GameSetupKeys.screen))
            .read<GameSetupCubit>()
            .state
            .blindGame,
        isTrue,
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(CatalogKeys.categoryScreen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(CatalogKeys.screen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(AllModesKeys.screen), findsOneWidget);
      expect(tester.getTopLeft(blind).dy, closeTo(origin, 1));
    },
  );
}
