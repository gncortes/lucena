import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/analytics/analytics_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/my_progress_keys.dart';
import 'package:lucena/ui/core/motion/valor_que_anima.dart';
import 'package:lucena/ui/my_progress/view_models/my_progress_cubit.dart';
import 'package:lucena/ui/my_progress/widgets/my_progress_screen.dart';

import '../../../testing/fakes/fake_account_invite_repository.dart';
import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_sync_repository.dart';
import '../../../testing/test_app.dart';

/// "Seu progresso" (H-CON-03, PropV2UxProgresso): rating grande com o
/// histórico, o convite da conta para quem não tem e as conquistas.
void main() {
  const achievements = [
    Achievement(id: 'first-fulfilled', type: AchievementType.firstFulfilled),
    Achievement(id: 'beat-1000', type: AchievementType.beatLevel, level: 1000),
    Achievement(id: 'beat-2600', type: AchievementType.beatLevel, level: 2600),
  ];

  late FakeAccountRepository accounts;
  late FakeAccountInviteRepository invite;
  late FakeRatingRepository rating;
  late FakeAchievementsRepository medals;

  setUp(() {
    accounts = FakeAccountRepository();
    invite = FakeAccountInviteRepository();
    rating = FakeRatingRepository(start: 1150);
    medals = FakeAchievementsRepository(achievements);
  });

  /// Duas partidas: 1443 e depois 1450 (+7), com a primeira conquista.
  Future<void> played() async {
    rating.entries.addAll([
      RatingEntry(
        rating: const PlayerRating(rating: 1443),
        at: DateTime.utc(2026, 10),
        gameId: 1,
      ),
      RatingEntry(
        rating: const PlayerRating(rating: 1450),
        at: DateTime.utc(2026, 10, 2),
        gameId: 2,
      ),
    ]);
    await medals.unlock([
      UnlockedAchievement(id: 'first-fulfilled', at: DateTime.utc(2026, 10)),
    ]);
  }

  MyProgressCubit cubit() => MyProgressCubit(
    rating: rating,
    achievements: medals,
    invite: invite,
    accounts: accounts,
  );

  Future<void> pumpScreen(WidgetTester tester, {bool load = true}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    final sync = SyncScheduler(accounts, FakeSyncRepository());
    addTearDown(sync.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(value: accounts),
              RepositoryProvider<SyncScheduler>.value(value: sync),
              RepositoryProvider<AnalyticsRepository>.value(
                value: FakeAnalyticsRepository(),
              ),
            ],
            child: BlocProvider(
              create: (_) {
                final created = cubit();
                if (load) created.load();
                return created;
              },
              child: const MyProgressScreen(),
            ),
          ),
        ),
        GoRoute(
          path: Routes.achievements,
          builder: (_, state) => Scaffold(body: Text('rota ${state.uri}')),
        ),
        GoRoute(
          path: Routes.rating,
          builder: (_, state) => Scaffold(body: Text('rota ${state.uri}')),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        router: router,
        locale: const Locale('pt'),
        child: const SizedBox(),
      ),
    );
    // O esqueleto brilha sem parar: só um quadro.
    load ? await tester.pumpAndSettle() : await tester.pump();
  }

  testWidgets('sem conta: o cartão "Salve seu progresso" fica abaixo do '
      'rating', (tester) async {
    await played();
    await pumpScreen(tester);
    expect(find.text('Seu progresso'), findsOneWidget);
    expect(find.text('Seu rating'), findsOneWidget);
    expect(find.text('1450'), findsOneWidget);
    expect(find.text('2 partidas'), findsOneWidget);
    final card = find.byKey(MyProgressKeys.accountCard);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Salve seu progresso')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(card).dy,
      greaterThan(tester.getBottomLeft(find.byKey(MyProgressKeys.rating)).dy),
    );
  });

  testWidgets('H-ANI-18: o rating e as partidas contam até o valor', (
    tester,
  ) async {
    await played();
    await pumpScreen(tester);
    for (final key in [MyProgressKeys.ratingValue, MyProgressKeys.games]) {
      expect(
        find.ancestor(
          of: find.byKey(key),
          matching: find.byType(ValorQueAnima),
        ),
        findsOneWidget,
        reason: '$key',
      );
    }
    expect(find.text('1450'), findsOneWidget);
    expect(find.text('2 partidas'), findsOneWidget);
  });

  testWidgets('com conta: sem o cartão, e o resto igual', (tester) async {
    await played();
    accounts = FakeAccountRepository(account: FakeAccountRepository.google);
    await pumpScreen(tester);
    expect(find.byKey(MyProgressKeys.accountCard), findsNothing);
    expect(find.byKey(MyProgressKeys.rating), findsOneWidget);
    expect(find.byKey(MyProgressKeys.achievementsAll), findsOneWidget);
    expect(find.byKey(MyProgressKeys.medal('first-fulfilled')), findsOneWidget);
  });

  testWidgets('"Ver todas" abre as Conquistas', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(MyProgressKeys.achievementsAll));
    await tester.pumpAndSettle();
    expect(find.text('rota ${Routes.achievements}'), findsOneWidget);
  });

  testWidgets('"Histórico" abre o histórico do rating', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(MyProgressKeys.history));
    await tester.pumpAndSettle();
    expect(find.text('rota ${Routes.rating}'), findsOneWidget);
  });

  testWidgets('vazio: 0 partidas, o rating inicial e as medalhas trancadas', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('0 partidas'), findsOneWidget);
    expect(find.text('1150'), findsOneWidget);
    for (final achievement in achievements) {
      expect(find.byKey(MyProgressKeys.medal(achievement.id)), findsOneWidget);
    }
    expect(find.byIcon(Icons.lock), findsNWidgets(achievements.length));
  });

  testWidgets('o X tira o cartão e suspende o convite por 7 dias', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(MyProgressKeys.accountClose));
    await tester.pumpAndSettle();
    expect(find.byKey(MyProgressKeys.accountCard), findsNothing);
    expect(invite.shown, isTrue);
  });

  testWidgets('convite suspenso: sem o cartão', (tester) async {
    invite = FakeAccountInviteRepository(shown: true);
    await pumpScreen(tester);
    expect(find.byKey(MyProgressKeys.accountCard), findsNothing);
  });

  testWidgets('carregando: o esqueleto no lugar do conteúdo', (tester) async {
    await pumpScreen(tester, load: false);
    expect(find.byKey(MyProgressKeys.loading), findsOneWidget);
    expect(find.byKey(MyProgressKeys.rating), findsNothing);
  });

  test('entrou na conta com a tela aberta: o cartão some', () async {
    final progress = cubit();
    addTearDown(progress.close);
    await progress.load();
    expect(progress.state.invite, isTrue);
    await accounts.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);
    expect(progress.state.invite, isFalse);
  });
}
