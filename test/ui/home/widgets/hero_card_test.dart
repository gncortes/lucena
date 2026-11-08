import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/theme/app_button.dart';
import 'package:lucena/ui/core/theme/app_spacing.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/hero_card.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

/// O cartão azul (T83): só o rótulo do lugar, o título, a barra (com
/// progresso), a miniatura e o botão.
void main() {
  Future<GoRouter> pump(WidgetTester tester, HomeState state) async {
    tester.view
      ..physicalSize = const Size(360, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: HeroCard(state: state),
              ),
            ),
          ),
        ),
        GoRoute(
          path: Routes.freeBoard,
          builder: (_, _) => const Scaffold(body: Text('tabuleiro livre')),
        ),
      ],
    );
    addTearDown(router.dispose);
    // A miniatura usa as cores do tabuleiro.
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  String text(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  String action(WidgetTester tester) => tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(HomeKeys.goalAction),
          matching: find.byType(Text),
        ),
      )
      .data!;

  testWidgets('sem nada a retomar: nenhum cartão (aprender a jogar, melhorar '
      'o jogo sem treino e sem Jornada)', (tester) async {
    for (final goal in [GoalPreference.learn, GoalPreference.improve, null]) {
      await pump(tester, HomeState(ready: true, goal: goal));

      expect(find.byKey(HomeKeys.goalCard), findsNothing, reason: '$goal');
    }
  });

  testWidgets('explorar posições: Tabuleiro livre, Sua última posição, '
      'Continuar', (tester) async {
    final router = await pump(
      tester,
      const HomeState(ready: true, goal: GoalPreference.explore),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Tabuleiro livre');
    expect(text(tester, HomeKeys.goalTitle), 'Sua última posição');
    expect(action(tester), 'Continuar');
    expect(find.byKey(HomeKeys.heroProgress), findsNothing);
    await tester.tap(find.byKey(HomeKeys.goalCard));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, Routes.freeBoard);
  });

  testWidgets('escola: a lição da vez e a barra', (tester) async {
    await pump(
      tester,
      const HomeState(
        ready: true,
        school: SchoolSummary(done: 2, total: 6, teacher: null),
      ),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Escola');
    expect(text(tester, HomeKeys.goalTitle), 'Lição 3');
    expect(action(tester), 'Continuar');
    expect(find.byKey(HomeKeys.heroProgress), findsOneWidget);
  });

  testWidgets('o cartão tem só o rótulo, o título e o botão de texto', (
    tester,
  ) async {
    await pump(
      tester,
      const HomeState(
        ready: true,
        school: SchoolSummary(done: 2, total: 6, teacher: null),
      ),
    );

    final texts = find.descendant(
      of: find.byKey(HomeKeys.goalCard),
      matching: find.byType(Text),
    );
    expect(texts, findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('o botão desenha 36 e toca em 48 (D6)', (tester) async {
    await pump(
      tester,
      const HomeState(ready: true, goal: GoalPreference.explore),
    );

    final button = find.byKey(HomeKeys.goalAction);
    final pill = find.descendant(of: button, matching: find.byType(Material));
    expect(tester.getSize(pill.first).height, kButtonHeightPill);
    expect(tester.getSize(button).height, kMinInteractiveDimension);
  });

  testWidgets('sem barra, o botão fica encostado à direita', (tester) async {
    await pump(
      tester,
      const HomeState(ready: true, goal: GoalPreference.explore),
    );

    final card = tester.getRect(find.byKey(HomeKeys.goalCard));
    final button = tester.getRect(find.byKey(HomeKeys.goalAction));
    // Só o padding do cartão (16) e a folga do toque de 48 à direita.
    expect(card.right - button.right, lessThanOrEqualTo(AppSpacing.lg));
  });
}
