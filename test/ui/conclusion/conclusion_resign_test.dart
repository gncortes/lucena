import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/conclusion/widgets/conclusion_screen.dart';
import 'package:lucena/ui/conclusion/widgets/outcome_badge.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

/// P9 B: a derrota por desistência (faixa cinza com a bandeira e "Para
/// aprender com ela"); mate e tempo seguem como antes.
void main() {
  // Final de torre com peão de torre: tem aula liberada (rook.lucena).
  final linked = samplePositions[2];
  // Mate de dama: o app não tem aula liberada para ele hoje.
  final unlinked = samplePositions[0];

  late GoRouter router;
  late String lastLocation;

  Future<void> open(
    WidgetTester tester, {
    required EndgamePosition position,
    GameEndReason reason = GameEndReason.resign,
    List<String> moves = const ['e1d1', 'e5d4'],
    Size size = const Size(360, 640),
  }) async {
    final progress = FakeProgressRepository();
    final now = FakeNow(DateTime.utc(2026, 11, 6, 12));
    late ConclusionCubit cubit;
    late int id;
    await tester.runAsync(() async {
      id = await progress.addAttempt(
        Attempt(
          positionId: position.id,
          playedAt: now(),
          startedAt: now().subtract(const Duration(seconds: 20)),
          outcome: AttemptOutcome.loss,
          fulfilled: false,
          opponent: OpponentKind.maia,
          opponentLevel: 1000,
          startFen: position.fen,
          userSide: Side.white,
          endReason: reason,
          moves: moves,
        ),
      );
      cubit = ConclusionCubit(
        progress: progress,
        rating: FakeRatingRepository(),
        achievements: FakeAchievementsRepository(),
        journey: FakeJourneyRepository(),
        speedruns: FakeSpeedrunRepository(progress),
        positions: FakePositionsRepository(),
        characters: FakeCharacterRepository(),
        now: now,
        analysis: FakeAnalysisRepository(),
        reviews: FakeGameReviewRepository(),
      );
      await cubit.load(id, 'pt');
    });
    addTearDown(cubit.close);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await tester.runAsync(settings.load);
    final accounts = FakeAccountRepository();
    lastLocation = '/';
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<SyncScheduler>(
                create: (_) => SyncScheduler(accounts, FakeSyncRepository()),
                dispose: (scheduler) => scheduler.dispose(),
              ),
            ],
            child: BlocProvider.value(
              value: cubit,
              child: const ConclusionScreen(),
            ),
          ),
        ),
        GoRoute(
          path: '/rating/game/:id',
          builder: (_, state) {
            lastLocation = state.uri.toString();
            return const Scaffold(body: Text('revisão'));
          },
        ),
        GoRoute(
          path: '/endgames/:id',
          builder: (_, state) {
            lastLocation = state.uri.toString();
            return const Scaffold(body: Text('lição'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        router: router,
        mediaBuilder: (context, child) => MediaQuery(
          data: MediaQueryData(size: size, disableAnimations: true),
          child: child!,
        ),
        child: const SizedBox(),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
    }
  }

  Color stripColor(WidgetTester tester) =>
      tester.widget<OutcomeStrip>(find.byKey(ConclusionKeys.goal)).color;

  testWidgets('desistência: faixa cinza com a bandeira e os dois itens', (
    tester,
  ) async {
    await open(tester, position: linked);
    final strip = tester.widget<OutcomeStrip>(find.byKey(ConclusionKeys.goal));
    expect(strip.mark, OutcomeMark.flag);
    final colors = Theme.of(tester.element(find.byKey(ConclusionKeys.goal)))
        .colorScheme;
    expect(strip.color, colors.onSurfaceVariant);
    expect(find.text('Objetivo não cumprido'), findsOneWidget);
    expect(find.text('Para aprender com ela'), findsOneWidget);
    expect(find.text('Ver a partida'), findsOneWidget);
    expect(find.text('Lance a lance, com a análise'), findsOneWidget);
    expect(find.text('Treinar este final'), findsOneWidget);
    expect(find.textContaining('volte à lição'), findsOneWidget);
  });

  testWidgets('"Ver a partida" abre a revisão da partida gravada', (
    tester,
  ) async {
    await open(tester, position: linked);
    await tester.ensureVisible(find.byKey(ConclusionKeys.learnGame));
    await tester.tap(find.byKey(ConclusionKeys.learnGame));
    await tester.pumpAndSettle();
    expect(lastLocation, startsWith('/rating/game/'));
    expect(find.text('revisão'), findsOneWidget);
  });

  testWidgets('"Treinar este final" abre a lição do final', (tester) async {
    await open(tester, position: linked);
    await tester.ensureVisible(find.byKey(ConclusionKeys.learnFinal));
    await tester.tap(find.byKey(ConclusionKeys.learnFinal));
    await tester.pumpAndSettle();
    expect(lastLocation, Routes.endgameLesson('rook.lucena'));
    expect(find.text('lição'), findsOneWidget);
  });

  testWidgets('derrota por mate: faixa vermelha e sem a lista, como antes', (
    tester,
  ) async {
    await open(tester, position: linked, reason: GameEndReason.checkmate);
    expect(
      tester.widget<OutcomeStrip>(find.byKey(ConclusionKeys.goal)).mark,
      OutcomeMark.cross,
    );
    final neutral = Theme.of(tester.element(find.byKey(ConclusionKeys.goal)))
        .colorScheme
        .onSurfaceVariant;
    expect(stripColor(tester), isNot(neutral));
    expect(find.byKey(ConclusionKeys.learn), findsNothing);
    expect(find.text('Para aprender com ela'), findsNothing);
  });

  testWidgets('derrota por tempo: faixa vermelha e sem a lista', (
    tester,
  ) async {
    await open(tester, position: linked, reason: GameEndReason.timeout);
    expect(
      tester.widget<OutcomeStrip>(find.byKey(ConclusionKeys.goal)).mark,
      OutcomeMark.cross,
    );
    expect(find.byKey(ConclusionKeys.learn), findsNothing);
  });

  testWidgets('final sem aula liberada: só "Ver a partida"', (tester) async {
    await open(tester, position: unlinked);
    expect(find.byKey(ConclusionKeys.learnGame), findsOneWidget);
    expect(find.byKey(ConclusionKeys.learnFinal), findsNothing);
    expect(find.text('Treinar este final'), findsNothing);
  });

  testWidgets('desistiu sem lance nenhum: não há partida para rever', (
    tester,
  ) async {
    await open(tester, position: unlinked, moves: const []);
    expect(find.byKey(ConclusionKeys.learnGame), findsNothing);
    expect(find.byKey(ConclusionKeys.learn), findsNothing);
  });

  testWidgets('360x640: sem estouro, lista visível e nada atrás do botão', (
    tester,
  ) async {
    await open(tester, position: linked);
    expect(tester.takeException(), isNull);
    final button = find.byKey(
      ConclusionKeys.action(ConclusionAction.playAgain),
    );
    expect(button, findsOneWidget);
    final top = tester.getTopLeft(button).dy;
    final scroll = tester.getRect(find.byType(SingleChildScrollView).first);
    // A rolagem termina onde o botão começa: nada fica por trás dele.
    expect(scroll.bottom, lessThanOrEqualTo(top + 1));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();
    final last = tester.getRect(find.byKey(ConclusionKeys.learnFinal));
    expect(last.bottom, lessThanOrEqualTo(top + 1));
    for (final key in [ConclusionKeys.learnGame, ConclusionKeys.learnFinal]) {
      expect(tester.getSize(find.byKey(key)).height, greaterThanOrEqualTo(48));
    }
  });
}
