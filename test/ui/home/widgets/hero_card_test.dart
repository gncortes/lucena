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

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

/// O cartão azul (T83): só o rótulo do lugar, o título, a barra (com
/// progresso), a miniatura e o botão.
void main() {
  EndgameSummary lucena({bool recommended = false, double progress = 0}) =>
      EndgameSummary(
        lessonId: 'rook.lucena',
        title: 'Posição de Lucena',
        score: 0,
        maxScore: 6,
        teacher: FakeCharacterRepository.viktor,
        recommended: recommended,
        progress: progress,
        fen: '8/8/8/8/8/8/8/K6k w - - 0 1',
      );

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
          path: Routes.endgameLesson('rook.lucena'),
          builder: (_, _) => const Scaffold(body: Text('aula aberta')),
        ),
        GoRoute(
          path: Routes.boardControls,
          builder: (_, _) => const Scaffold(body: Text('como mover')),
        ),
        GoRoute(
          path: Routes.speedruns,
          builder: (_, _) => const Scaffold(body: Text('speedrun')),
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

  testWidgets('aprender a jogar, antes da 1ª partida: os primeiros passos', (
    tester,
  ) async {
    await pump(
      tester,
      const HomeState(ready: true, goal: GoalPreference.learn),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Primeiros passos');
    expect(text(tester, HomeKeys.goalTitle), 'Como mover as peças');
    expect(action(tester), 'Começar');
    expect(find.byKey(HomeKeys.heroBoard), findsOneWidget);
    expect(find.byKey(HomeKeys.heroProgress), findsNothing);
    await tester.tap(find.byKey(HomeKeys.goalAction));
    await tester.pumpAndSettle();
    expect(find.text('como mover'), findsOneWidget);
  });

  testWidgets('aprender finais, 1º capítulo: Começar, sem barra', (
    tester,
  ) async {
    await pump(
      tester,
      HomeState(
        ready: true,
        goal: GoalPreference.endgames,
        endgame: lucena(recommended: true),
      ),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Curso de finais');
    expect(text(tester, HomeKeys.goalTitle), 'Posição de Lucena');
    expect(action(tester), 'Começar');
    expect(find.byKey(HomeKeys.heroProgress), findsNothing);
    await tester.tap(find.byKey(HomeKeys.goalAction));
    await tester.pumpAndSettle();
    expect(find.text('aula aberta'), findsOneWidget);
  });

  testWidgets('capítulo no meio: a barra e Continuar', (tester) async {
    await pump(
      tester,
      HomeState(
        ready: true,
        goal: GoalPreference.endgames,
        endgame: lucena(progress: 0.4),
      ),
    );

    expect(action(tester), 'Continuar');
    expect(find.byKey(HomeKeys.heroProgress), findsOneWidget);
    expect(find.byKey(HomeKeys.heroBoard), findsOneWidget);
  });

  testWidgets('curso concluído: Treinar, sem tabuleiro', (tester) async {
    await pump(
      tester,
      const HomeState(
        ready: true,
        goal: GoalPreference.endgames,
        courseDone: true,
      ),
    );

    expect(text(tester, HomeKeys.heroLabel), 'Curso de finais');
    expect(text(tester, HomeKeys.goalTitle), 'Curso concluído');
    expect(action(tester), 'Treinar');
    expect(find.byKey(HomeKeys.heroBoard), findsNothing);
  });

  testWidgets('nada por fazer: o speedrun do Coco ao Stockfish', (
    tester,
  ) async {
    await pump(tester, const HomeState(ready: true));

    expect(text(tester, HomeKeys.heroLabel), 'Speedrun');
    expect(text(tester, HomeKeys.goalTitle), 'Do Coco ao Stockfish');
    expect(action(tester), 'Jogar');
    expect(find.byKey(HomeKeys.heroBoard), findsNothing);
    await tester.tap(find.byKey(HomeKeys.goalCard));
    await tester.pumpAndSettle();
    expect(find.text('speedrun'), findsOneWidget);
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
      HomeState(
        ready: true,
        goal: GoalPreference.endgames,
        endgame: lucena(progress: 0.4),
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
    await pump(tester, const HomeState(ready: true));

    final button = find.byKey(HomeKeys.goalAction);
    final pill = find.descendant(of: button, matching: find.byType(Material));
    expect(tester.getSize(pill.first).height, kButtonHeightPill);
    expect(tester.getSize(button).height, kMinInteractiveDimension);
  });

  testWidgets('sem barra, o botão fica encostado à direita', (tester) async {
    await pump(tester, const HomeState(ready: true));

    final card = tester.getRect(find.byKey(HomeKeys.goalCard));
    final button = tester.getRect(find.byKey(HomeKeys.goalAction));
    // Só o padding do cartão (16) e a folga do toque de 48 à direita.
    expect(card.right - button.right, lessThanOrEqualTo(AppSpacing.lg));
  });
}
