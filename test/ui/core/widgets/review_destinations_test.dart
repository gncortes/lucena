import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/data/repositories/achievements/achievements_repository.dart';
import 'package:lucena/data/repositories/analysis/analysis_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/journey/journey_repository.dart';
import 'package:lucena/data/repositories/progress/progress_repository.dart';
import 'package:lucena/data/repositories/rating/rating_repository.dart';
import 'package:lucena/data/repositories/review/game_review_repository.dart';
import 'package:lucena/data/repositories/school/lesson_repository.dart';
import 'package:lucena/data/repositories/speedrun/speedrun_repository.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/routing/review_destinations.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/core/keys/rating_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/player_card.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';
import 'package:lucena/ui/history/view_models/history_cubit.dart';
import 'package:lucena/ui/history/widgets/history_screen.dart';

import '../../../../testing/fakes/fake_achievements_repository.dart';
import '../../../../testing/fakes/fake_analysis_repository.dart';
import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_game_review_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../../testing/test_app.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';

import 'package:lucena/data/repositories/settings/settings_repository.dart';

class _RequestedProgress extends FakeProgressRepository {
  final requested = <List<int>>[];
  @override
  Future<Map<int, Attempt>> attemptsById(Iterable<int> ids) {
    requested.add(ids.toList());
    return super.attemptsById(ids);
  }
}

Widget _repositories(
  Widget child,
  _RequestedProgress progress, {
  FakeRatingRepository? rating,
}) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<ProgressRepository>.value(value: progress),
    RepositoryProvider<RatingRepository>.value(
      value: rating ?? FakeRatingRepository(),
    ),
    RepositoryProvider<CharacterRepository>.value(
      value: FakeCharacterRepository(),
    ),
    RepositoryProvider<AnalysisRepository>.value(
      value: FakeAnalysisRepository(),
    ),
    RepositoryProvider<GameReviewRepository>.value(
      value: FakeGameReviewRepository(),
    ),
    RepositoryProvider<LessonRepository>.value(value: FakeLessonRepository()),
    RepositoryProvider<SettingsRepository>.value(
      value: FakeSettingsRepository(),
    ),
    RepositoryProvider<AchievementsRepository>.value(
      value: FakeAchievementsRepository(),
    ),
    RepositoryProvider<SpeedrunRepository>.value(
      value: FakeSpeedrunRepository(progress),
    ),
    RepositoryProvider<JourneyRepository>.value(value: FakeJourneyRepository()),
    RepositoryProvider<Now>.value(value: FakeNow(DateTime.utc(2026, 10, 11))),
  ],
  child: child,
);

void main() {
  for (final (details, player) in [
    (false, false),
    (true, false),
    (false, true),
  ]) {
    testWidgets(
      'shared destination factory details=$details player=$player: id/locale and provider lifetime',
      (tester) async {
        final progress = _RequestedProgress();
        final lessons = FakeLessonRepository();
        await tester.pumpWidget(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ProgressRepository>.value(value: progress),
              RepositoryProvider<RatingRepository>.value(
                value: FakeRatingRepository(),
              ),
              RepositoryProvider<CharacterRepository>.value(
                value: FakeCharacterRepository(),
              ),
              RepositoryProvider<AnalysisRepository>.value(
                value: FakeAnalysisRepository(),
              ),
              RepositoryProvider<GameReviewRepository>.value(
                value: FakeGameReviewRepository(),
              ),
              RepositoryProvider<LessonRepository>.value(value: lessons),
              RepositoryProvider<SettingsRepository>.value(
                value: FakeSettingsRepository(),
              ),
              RepositoryProvider<AchievementsRepository>.value(
                value: FakeAchievementsRepository(),
              ),
              RepositoryProvider<SpeedrunRepository>.value(
                value: FakeSpeedrunRepository(progress),
              ),
              RepositoryProvider<JourneyRepository>.value(
                value: FakeJourneyRepository(),
              ),
              RepositoryProvider<Now>.value(
                value: FakeNow(DateTime.utc(2026, 10, 11)),
              ),
            ],
            child: TestApp(
              locale: const Locale('pt'),
              child: Builder(
                builder: (context) => player
                    ? const Scaffold(
                        body: PlayerCard(
                          state: HomeState(ready: true, rating: 1150),
                        ),
                      )
                    : details
                    ? gameDetailsDestination(context, 77)
                    : ratingDestination(context, highlightedGame: 77),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (player) {
          final ink = find.descendant(
            of: find.byKey(HomeKeys.playerCard),
            matching: find.byType(InkWell),
          );
          expect(ink.hitTestable(), findsOneWidget);
          final open = tester.widget<InkWell>(ink).onTap!;
          open();
          open();
          await tester.pumpAndSettle();
          expect(find.byKey(RatingKeys.screen), findsOneWidget);
        }
        if (details) {
          final cubit = tester
              .element(find.byKey(GameDetailsKeys.screen))
              .read<GameDetailsCubit>();
          expect(progress.requested, [
            [77],
          ]);
          expect(lessons.languages, ['pt']);
          expect(cubit.state.ready, isTrue);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          expect(cubit.isClosed, isTrue);
        } else {
          final cubit = tester
              .element(find.byKey(RatingKeys.screen))
              .read<HistoryCubit>();
          expect(cubit.state.highlightedGame, player ? isNull : 77);
          expect(
            tester
                .widget<HistoryScreen>(find.byType(HistoryScreen))
                .gameDestinationBuilder,
            same(gameDetailsDestination),
          );
          if (player) {
            await tester.tap(find.byType(BackButton));
            await tester.pumpAndSettle();
            expect(
              find.byKey(HomeKeys.playerCard).hitTestable(),
              findsOneWidget,
            );
          } else {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump();
          }
          expect(cubit.isClosed, isTrue);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final reduced in [false, true]) {
    testWidgets(
      'real GoRouter reduced=$reduced: empty rating closes before catalog; destination disposed',
      (tester) async {
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduced);
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.view.reset);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final progress = _RequestedProgress();
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(
                body: PlayerCard(state: HomeState(ready: true, rating: 1150)),
              ),
            ),
            GoRoute(
              path: Routes.rating,
              builder: (context, _) => ratingDestination(context),
            ),
            GoRoute(
              path: Routes.catalog,
              builder: (_, _) => const Scaffold(body: Text('visible catalog')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          _repositories(
            TestApp(router: router, child: const SizedBox.shrink()),
            progress,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(HomeKeys.playerCard));
        await tester.pumpAndSettle();
        final rating = tester
            .element(find.byKey(RatingKeys.screen))
            .read<HistoryCubit>();
        expect(router.routeInformationProvider.value.uri.path, '/');
        final action = find.byKey(RatingKeys.emptyHistoryAction);
        await tester.scrollUntilVisible(
          action,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, Routes.catalog);
        expect(find.text('visible catalog').hitTestable(), findsOneWidget);
        expect(
          find.byKey(RatingKeys.screen, skipOffstage: false),
          findsNothing,
        );
        expect(rating.isClosed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'real GoRouter reduced=$reduced: detail keeps id and returns with one reload/provider disposal',
      (tester) async {
        tester.view
          ..physicalSize = const Size(360, 800)
          ..devicePixelRatio = 1;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduced);
        addTearDown(tester.view.reset);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final progress = _RequestedProgress();
        final attempt = Attempt(
          positionId: 'basic.queen.0001',
          playedAt: DateTime.utc(2026, 10, 11),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          opponentLevel: 1000,
        );
        final id = await progress.addAttempt(attempt);
        // O Histórico lista as partidas que o rating contou.
        final ratings = FakeRatingRepository();
        await ratings.rate(
          attempt,
          userSide: Side.white,
          drawGoal: false,
          gameId: id,
        );
        final router = GoRouter(
          initialLocation: Routes.rating,
          routes: [
            GoRoute(
              path: Routes.rating,
              builder: (context, _) => ratingDestination(context),
              routes: [
                GoRoute(
                  path: 'game/:id',
                  builder: (context, state) => gameDetailsDestination(
                    context,
                    int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          _repositories(
            TestApp(router: router, child: const SizedBox.shrink()),
            progress,
            rating: ratings,
          ),
        );
        await tester.pumpAndSettle();
        final rating = tester
            .element(find.byKey(RatingKeys.screen))
            .read<HistoryCubit>();
        var reloads = 0;
        final subscription = rating.stream.listen((_) => reloads++);
        addTearDown(subscription.cancel);
        final row = find.byKey(RatingKeys.entry(0));
        await tester.scrollUntilVisible(
          row,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(row.hitTestable(), findsOneWidget);
        int requestsFor(int id) => progress.requested
            .where((ids) => ids.length == 1 && ids.first == id)
            .length;
        // A leitura do Histórico também pede a partida: só o que vem depois
        // de abrir é do detalhe.
        final before = requestsFor(id);
        final open = tester.widget<InkWell>(row).onTap!;
        open();
        open();
        await tester.pumpAndSettle();
        final details = tester
            .element(find.byKey(GameDetailsKeys.screen))
            .read<GameDetailsCubit>();
        expect(details.state.attempt, same(attempt));
        expect(requestsFor(id) - before, 1);
        expect(router.routeInformationProvider.value.uri.path, Routes.rating);
        expect(find.byType(BackButton).hitTestable(), findsOneWidget);
        await tester.tap(find.byType(BackButton).hitTestable());
        await tester.pumpAndSettle();
        expect(details.isClosed, isTrue);
        expect(rating.isClosed, isFalse);
        expect(reloads, 1);
        expect(row.hitTestable(), findsOneWidget);
        expect(
          tester.element(find.byKey(RatingKeys.screen)).read<HistoryCubit>(),
          same(rating),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
