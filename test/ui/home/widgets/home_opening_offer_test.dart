import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/training/demo_offer_rules.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_activity_repository.dart';
import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../../testing/fakes/fake_opening_offer_repository.dart';
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_purchase_service.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

/// H-INI-14 (com a regra da H-VEN-15): a oferta do Pilares abre por cima do
/// Início, no máximo 2 vezes, com 3 dias entre elas, nunca na abertura do
/// tour nem junto da folha da sequência perdida, e nunca para quem comprou.
void main() {
  final today = DateTime(2026, 11, 4, 9);

  Set<DateTime> run(int days) => {
    for (var i = 0; i < days; i++) DateTime(2026, 11, 2 - i),
  };

  late FakeOpeningOfferRepository offer;
  late GoRouter router;

  Future<void> open(
    WidgetTester tester, {
    Onboarding onboarding = const Onboarding(done: true),
    PilaresAccessKind access = PilaresAccessKind.demo,
    DemoOfferState counter = const DemoOfferState(),
    Set<DateTime> days = const {},
    bool keep = false,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = FakeNow(today);
    offer = keep ? offer : FakeOpeningOfferRepository(state: counter, now: now);
    final activity = FakeActivityRepository(days: days, now: now);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => SettingsCubit(
                  FakeSettingsRepository(const AppSettings()),
                  languages: AppLanguage.selectable,
                )..load(),
              ),
              BlocProvider(
                create: (_) => HomeCubit(
                  journey: FakeJourneyRepository(),
                  progress: FakeProgressRepository(),
                  onboarding: FakeOnboardingRepository(onboarding),
                  characters: FakeCharacterRepository(),
                  rating: FakeRatingRepository(),
                  lessons: FakeLessonRepository(),
                  school: FakeSchoolProgressRepository(),
                  profile: FakeProfileRepository(const UserProfile()),
                  endgameLessons: FakeEndgameLessonRepository(),
                  endgameProgress: FakeEndgameProgressRepository(),
                  homeLayout: FakeHomeLayoutRepository(),
                  now: now,
                  activity: activity,
                  positions: FakePositionsRepository(),
                  analytics: FakeAnalyticsRepository(),
                  openingOffer: offer,
                  purchases: FakePurchaseRepository(
                    PurchaseState(access: PilaresAccess(kind: access)),
                  ),
                )..load(),
              ),
            ],
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          // A oferta antes do Início (H-VEN-15): a folha da D2.
          path: D2Paths.pilaresBeforeHome,
          builder: (_, _) =>
              const Scaffold(body: Text('oferta antes do início')),
        ),
        GoRoute(
          path: '/tour',
          builder: (_, _) => const Scaffold(body: Text('tour')),
        ),
        GoRoute(
          path: '/goal',
          builder: (_, _) => const Scaffold(body: Text('objetivo')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('demo, nunca vista: abre a oferta antes do Início e '
      'conta a vez ao abrir', (tester) async {
    await open(tester);
    expect(find.text('oferta antes do início'), findsOneWidget);
    expect(offer.state.count, 1);
    expect(offer.state.lastShown, today);
  });

  testWidgets('voltar da oferta: o Início fica, sem abrir de novo', (
    tester,
  ) async {
    await open(tester);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(find.textContaining('oferta'), findsNothing);
    expect(offer.state.count, 1);
  });

  testWidgets('comprador nunca vê', (tester) async {
    for (final kind in [
      PilaresAccessKind.lifetime,
      PilaresAccessKind.monthlyActive,
      PilaresAccessKind.monthlyGrace,
    ]) {
      await open(tester, access: kind);
      expect(find.textContaining('oferta'), findsNothing, reason: '$kind');
      expect(offer.state.count, 0);
    }
  });

  testWidgets('assinatura encerrada volta a ver (é demo)', (tester) async {
    await open(tester, access: PilaresAccessKind.monthlyEnded);
    expect(find.text('oferta antes do início'), findsOneWidget);
  });

  testWidgets('já mostrada 2 vezes: não abre mais', (tester) async {
    await open(
      tester,
      counter: DemoOfferState(
        count: 2,
        lastShown: today.subtract(const Duration(days: 30)),
      ),
    );
    expect(find.textContaining('oferta'), findsNothing);
  });

  testWidgets('menos de 3 dias desde a última: espera', (tester) async {
    await open(
      tester,
      counter: DemoOfferState(
        count: 1,
        lastShown: today.subtract(const Duration(days: 2)),
      ),
    );
    expect(find.textContaining('oferta'), findsNothing);
  });

  testWidgets('3 dias depois da 1ª: abre a 2ª', (tester) async {
    await open(
      tester,
      counter: DemoOfferState(
        count: 1,
        lastShown: today.subtract(const Duration(days: 3)),
      ),
    );
    expect(find.text('oferta antes do início'), findsOneWidget);
    expect(offer.state.count, 2);
  });

  testWidgets('abertura do tour: vai ao tour e a oferta não abre na volta '
      'ao Início (mesma abertura)', (tester) async {
    await open(
      tester,
      onboarding: const Onboarding(stage: OnboardingStage.tour),
    );
    expect(find.text('tour'), findsOneWidget);
    expect(offer.tourThisOpening, isTrue);
    // O tour acabou e o Início abre de novo no mesmo processo.
    await open(tester, keep: true);
    expect(find.textContaining('oferta'), findsNothing);
    expect(offer.state.count, 0);
  });

  testWidgets('oferta e sequência perdida na mesma abertura: só a oferta; '
      'a folha espera a próxima abertura', (tester) async {
    await open(tester, days: run(12));
    expect(find.text('oferta antes do início'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
  });

  testWidgets('a oferta já apareceu nesta abertura: o Início recriado não '
      'abre a folha da sequência perdida', (tester) async {
    await open(tester, days: run(12));
    await open(tester, days: run(12), keep: true);
    expect(find.textContaining('oferta'), findsNothing);
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
  });
}
