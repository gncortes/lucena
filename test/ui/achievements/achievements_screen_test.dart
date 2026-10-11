import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/achievements/view_models/achievement_facts_loader.dart';
import 'package:lucena/ui/achievements/view_models/achievements_cubit.dart';
import 'package:lucena/ui/achievements/widgets/achievement_detail.dart';
import 'package:lucena/ui/achievements/widgets/achievements_screen.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/core/theme/app_theme.dart';

import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';

void main() {
  const achievements = [
    Achievement(id: 'first-fulfilled', type: AchievementType.firstFulfilled),
    Achievement(
      id: 'rung-1000-completed',
      type: AchievementType.rungCompleted,
      rungId: '1000',
    ),
    Achievement(id: 'beat-1000', type: AchievementType.beatLevel, level: 1000),
    Achievement(id: 'beat-2600', type: AchievementType.beatLevel, level: 2600),
    Achievement(
      id: 'all-levels-queen',
      type: AchievementType.allLevels,
      subcategory: 'queen',
    ),
    Achievement(id: 'first-speedrun', type: AchievementType.speedrunCompleted),
  ];
  // Meio-dia: a data relativa não depende do fuso de quem roda o teste.
  final now = DateTime(2026, 10, 8, 12);

  late FakeAchievementsRepository repository;
  late FakeProgressRepository progress;

  setUp(() async {
    repository = FakeAchievementsRepository(achievements);
    // Um dos dois desafios do degrau 1000 concluído.
    progress = FakeProgressRepository([
      Attempt(
        positionId: sampleLadder[0].challenges[0].position.id,
        playedAt: now,
        outcome: AttemptOutcome.win,
        fulfilled: true,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        challengeId: sampleLadder[0].challenges[0].id,
      ),
    ]);
    await repository.unlock([
      UnlockedAchievement(
        id: 'beat-2600',
        at: now.subtract(const Duration(hours: 2)),
        gameId: 9,
      ),
      // Com a partida de origem.
      UnlockedAchievement(
        id: 'first-fulfilled',
        at: DateTime(2026, 10, 7, 22, 41),
        gameId: 7,
      ),
      // Gravada antes da origem existir: só a data.
      UnlockedAchievement(id: 'beat-1000', at: DateTime(2026, 10, 5, 9)),
    ]);
  });

  AchievementsCubit cubit() => AchievementsCubit(
    repository,
    now: FakeNow(now),
    facts: AchievementFactsLoader(
      journey: FakeJourneyRepository(),
      progress: progress,
      speedruns: FakeSpeedrunRepository(progress),
      positions: FakePositionsRepository(),
    ),
  );

  /// A lista dentro de um roteador, com as rotas que o detalhe abre.
  Future<void> pumpScreen(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider(
            create: (_) => cubit()..load(),
            child: const AchievementsScreen(),
          ),
        ),
        GoRoute(
          path: '/rating/game/:id',
          builder: (context, state) =>
              Scaffold(body: Text('game ${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/journey/:rung',
          builder: (context, state) =>
              Scaffold(body: Text('rung ${state.pathParameters['rung']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.of(Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  double top(WidgetTester tester, String id) =>
      tester.getTopLeft(find.byKey(AchievementsKeys.item(id))).dy;

  Future<void> open(WidgetTester tester, String id) async {
    await tester.scrollUntilVisible(
      find.byKey(AchievementsKeys.item(id)),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(AchievementsKeys.item(id)));
    await tester.pumpAndSettle();
  }

  testWidgets('progresso geral no topo e grupos com o progresso de cada um', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(text(tester, AchievementsKeys.progress), '3 of 6 unlocked');
    expect(find.byKey(AchievementsKeys.progressBar), findsOneWidget);
    expect(text(tester, AchievementsKeys.group('journey')), 'Journey · 1 of 2');
    expect(
      text(tester, AchievementsKeys.group('opponents')),
      'Opponents · 2 of 3',
    );
    await tester.scrollUntilVisible(
      find.byKey(AchievementsKeys.group('speedrun')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      text(tester, AchievementsKeys.group('speedrun')),
      'Speedrun · 0 of 1',
    );
    // O grupo vem antes das conquistas dele.
    expect(
      tester.getTopLeft(find.byKey(AchievementsKeys.group('speedrun'))).dy,
      lessThan(top(tester, 'first-speedrun')),
    );
  });

  testWidgets('as que faltam aparecem com cadeado e o progresso quando dá '
      'para medir', (tester) async {
    await pumpScreen(tester);

    expect(
      find.byKey(AchievementsKeys.locked('rung-1000-completed')),
      findsOneWidget,
    );
    expect(
      text(tester, AchievementsKeys.itemProgress('rung-1000-completed')),
      '1 of 2 challenges',
    );
    expect(
      text(tester, AchievementsKeys.itemProgress('all-levels-queen')),
      // A vitória do desafio do degrau foi num final de dama.
      '1 of 9 levels',
    );
    // Obtida: sem cadeado; e a que não dá para medir, sem progresso.
    expect(find.byKey(AchievementsKeys.locked('beat-2600')), findsNothing);
    expect(
      find.byKey(AchievementsKeys.itemProgress('first-speedrun')),
      findsNothing,
    );
  });

  testWidgets('data relativa e curta na linha', (tester) async {
    await pumpScreen(tester);

    expect(text(tester, AchievementsKeys.unlockedOn('beat-2600')), 'today');
    expect(
      text(tester, AchievementsKeys.unlockedOn('first-fulfilled')),
      'yesterday',
    );
    expect(
      text(tester, AchievementsKeys.unlockedOn('beat-1000')),
      '3 days ago',
    );
  });

  testWidgets('filtro: conquistadas, faltando e o histórico pela data', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(AchievementsKeys.filter('unlocked')));
    await tester.pumpAndSettle();
    expect(find.byKey(AchievementsKeys.item('beat-2600')), findsOneWidget);
    expect(
      find.byKey(AchievementsKeys.item('rung-1000-completed')),
      findsNothing,
    );

    await tester.tap(find.byKey(AchievementsKeys.filter('locked')));
    await tester.pumpAndSettle();
    expect(find.byKey(AchievementsKeys.item('beat-2600')), findsNothing);
    expect(
      find.byKey(AchievementsKeys.item('rung-1000-completed')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(AchievementsKeys.filter('history')));
    await tester.pumpAndSettle();
    // A mais recente primeiro, sem os grupos.
    expect(find.byKey(AchievementsKeys.group('opponents')), findsNothing);
    expect(top(tester, 'beat-2600'), lessThan(top(tester, 'first-fulfilled')));
    expect(top(tester, 'first-fulfilled'), lessThan(top(tester, 'beat-1000')));
    expect(find.byKey(AchievementsKeys.item('first-speedrun')), findsNothing);
  });

  testWidgets('detalhe da conquistada com partida de origem: data completa e '
      '"Ver a partida" abre a revisão dela', (tester) async {
    await pumpScreen(tester);
    await open(tester, 'first-fulfilled');

    expect(find.byKey(AchievementsKeys.detail), findsOneWidget);
    expect(text(tester, AchievementsKeys.detailTitle), 'First endgame');
    expect(
      text(tester, AchievementsKeys.detailDescription),
      'Complete the goal of an endgame for the first time',
    );
    expect(
      text(tester, AchievementsKeys.detailDate),
      // O intl separa a hora do PM com um espaço fino.
      'Unlocked on Oct 7, 2026, 10:41\u202fPM',
    );
    expect(find.byKey(AchievementsKeys.detailShortcut), findsNothing);

    await tester.tap(find.byKey(AchievementsKeys.detailOpenGame));
    await tester.pumpAndSettle();
    expect(find.text('game 7'), findsOneWidget);
  });

  testWidgets('detalhe da conquistada antes da origem existir: só a data', (
    tester,
  ) async {
    await pumpScreen(tester);
    await open(tester, 'beat-1000');

    expect(
      text(tester, AchievementsKeys.detailDate),
      startsWith('Unlocked on Oct 5, 2026'),
    );
    expect(find.byKey(AchievementsKeys.detailOpenGame), findsNothing);
    expect(find.byKey(AchievementsKeys.detailOpenSpeedrun), findsNothing);
  });

  testWidgets('detalhe da que falta: o progresso e o atalho para o degrau', (
    tester,
  ) async {
    await pumpScreen(tester);
    await open(tester, 'rung-1000-completed');

    expect(find.byKey(AchievementsKeys.detailDate), findsNothing);
    expect(text(tester, AchievementsKeys.detailProgress), '1 of 2 challenges');
    expect(find.text('Play against Maia 1000'), findsOneWidget);

    await tester.tap(find.byKey(AchievementsKeys.detailShortcut));
    await tester.pumpAndSettle();
    expect(find.text('rung 1000'), findsOneWidget);
  });

  test('origem: a tentativa nas conquistas de speedrun, a partida nas '
      'outras', () {
    const speedrun = Achievement(
      id: 'first-speedrun',
      type: AchievementType.speedrunCompleted,
    );
    const beat = Achievement(
      id: 'beat-1000',
      type: AchievementType.beatLevel,
      level: 1000,
    );
    final both = UnlockedAchievement(
      id: 'x',
      at: now,
      gameId: 4,
      speedrunAttemptId: 2,
    );

    expect(AchievementDetail.sourceOf(speedrun, both, 'ending.rook'), (
      Routes.speedrunAttempt('ending.rook', 2),
      true,
    ));
    expect(AchievementDetail.sourceOf(beat, both, 'ending.rook'), (
      Routes.game(4),
      false,
    ));
    // Sem saber o speedrun da tentativa, a partida.
    expect(AchievementDetail.sourceOf(speedrun, both, null), (
      Routes.game(4),
      false,
    ));
    expect(
      AchievementDetail.sourceOf(
        beat,
        UnlockedAchievement(id: 'x', at: now),
        null,
      ),
      isNull,
    );
  });
}
