import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/achievements/view_models/achievement_facts_loader.dart';
import 'package:lucena/ui/achievements/view_models/achievements_cubit.dart';
import 'package:lucena/ui/achievements/widgets/achievements_screen.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/barra_que_enche.dart';
import 'package:lucena/ui/core/motion/shimmer_conteudo.dart';
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

  testWidgets('H-ANI-07: primeira carga brilha e o conteúdo surge', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byType(ShimmerConteudo), findsOneWidget);
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    expect(find.byKey(AchievementsKeys.progressBar), findsOneWidget);
  });

  testWidgets('H-ANI-13: a barra do total é a BarraQueEnche', (tester) async {
    await pumpScreen(tester);
    expect(
      find.descendant(
        of: find.byKey(AchievementsKeys.progressBar),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(find.byType(BarraQueEnche), findsWidgets);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: find.byKey(AchievementsKeys.progressBar),
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value,
      0.5,
    );
  });

  testWidgets('H-ANI-17: títulos e medalhas são itens da ListaEmOrdem', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byKey(MotionKeys.itemDaLista(0)), findsOneWidget);
    expect(find.byKey(MotionKeys.itemDaLista(1)), findsOneWidget);
  });
}
