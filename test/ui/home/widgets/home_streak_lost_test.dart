import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/user_profile.dart';
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
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

/// H-INI-08: a folha da sequência perdida aberta pelo Início.
void main() {
  // Hoje é 22/10; o último dia da sequência foi anteontem (20/10).
  final today = DateTime(2026, 10, 22, 9);

  Set<DateTime> run(int days) => {
    for (var i = 0; i < days; i++) DateTime(2026, 10, 20 - i),
  };

  late FakeActivityRepository activity;
  late FakeAnalyticsRepository analytics;
  late FakeNow now;
  late GoRouter router;

  Future<void> open(
    WidgetTester tester, {
    required Set<DateTime> days,
    Onboarding onboarding = const Onboarding(done: true),
    bool keep = false,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    now = FakeNow(today);
    // O mesmo aparelho ao reabrir: o que foi gravado fica.
    activity = keep ? activity : FakeActivityRepository(days: days, now: now);
    analytics = FakeAnalyticsRepository();
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
                  analytics: analytics,
                )..load(),
              ),
            ],
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/daily',
          builder: (_, _) => const Scaffold(body: Text('final do dia')),
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

  testWidgets('12 dias perdidos: a folha sai com o título e o recorde', (
    tester,
  ) async {
    await open(tester, days: run(12));
    expect(find.byKey(StreakKeys.lostSheet), findsOneWidget);
    expect(find.text('A sequência de 12 dias acabou'), findsOneWidget);
    expect(find.textContaining('recorde de 12 dias'), findsOneWidget);
  });

  testWidgets('o fundo da folha é o da tela (#F5F7F4)', (tester) async {
    await open(tester, days: run(12));
    final sheet = tester.widget<Material>(find.byKey(StreakKeys.lostSheet));
    expect(sheet.color, const Color(0xFFF5F7F4));
    final screen = Theme.of(tester.element(find.byKey(StreakKeys.lostSheet)))
        .colorScheme
        .surface;
    expect(sheet.color, screen);
  });

  testWidgets('"Agora não": fecha, registra agora_nao e não volta', (
    tester,
  ) async {
    await open(tester, days: run(12));
    await tester.tap(find.byKey(StreakKeys.lostNo));
    await tester.pumpAndSettle();
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
    final event = analytics.eventsNamed('sequencia_perdida').single;
    expect(event.params['acao'], 'agora_nao');
    expect(event.params['tamanho'], 12);
    expect(activity.lostShown, DateTime(2026, 10, 20));
    // Reabrir o app no mesmo dia: a folha foi gravada ao sair.
    await open(tester, days: run(12), keep: true);
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
  });

  testWidgets('o voltar do sistema vale "Agora não"', (tester) async {
    await open(tester, days: run(12));
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
    expect(
      analytics.eventsNamed('sequencia_perdida').single.params['acao'],
      'agora_nao',
    );
  });

  testWidgets('"Jogar o final do dia": abre o final e registra jogou_hoje', (
    tester,
  ) async {
    await open(tester, days: run(12));
    await tester.tap(find.byKey(StreakKeys.lostPlay));
    await tester.pumpAndSettle();
    expect(find.text('final do dia'), findsOneWidget);
    expect(
      analytics.eventsNamed('sequencia_perdida').single.params['acao'],
      'jogou_hoje',
    );
  });

  testWidgets('a folha é gravada ao abrir: fechar à força não repete', (
    tester,
  ) async {
    await open(tester, days: run(12));
    expect(find.byKey(StreakKeys.lostSheet), findsOneWidget);
    // Sem responder: já está gravada.
    expect(activity.lostShown, DateTime(2026, 10, 20));
    await open(tester, days: run(12), keep: true);
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
  });

  testWidgets('sequência perdida de 1 dia: sem folha', (tester) async {
    await open(tester, days: run(1));
    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
  });

  testWidgets('primeira abertura com o tour pendente: sem folha', (
    tester,
  ) async {
    await open(
      tester,
      days: run(12),
      onboarding: const Onboarding(stage: OnboardingStage.tour),
    );
    expect(find.byKey(StreakKeys.lostSheet), findsNothing);
    expect(find.text('tour'), findsOneWidget);
  });
}
