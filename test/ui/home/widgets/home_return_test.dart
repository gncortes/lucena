import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/widgets/reload_on_return.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_activity_repository.dart';
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

/// A primeira leitura espera o teste soltar; as seguintes passam direto.
class _GatedProgress extends FakeProgressRepository {
  final firstRead = Completer<Set<String>>();
  var _reads = 0;

  @override
  Future<Set<String>> fulfilledChallenges() {
    if (_reads++ == 0) return firstRead.future;
    return super.fulfilledChallenges();
  }
}

class _FirstLoad extends Cubit<int> {
  _FirstLoad(HomeCubit home) : super(0) {
    unawaited(home.load('pt'));
  }
}

/// H-INI-13: o Início sempre atual ao voltar de outra tela ou do segundo plano.
void main() {
  final day1 = DateTime(2026, 10, 22, 9);

  HomeCubit cubit({
    FakeProgressRepository? progress,
    FakeNow? now,
    FakeActivityRepository? activity,
    Onboarding onboarding = const Onboarding(done: true),
  }) {
    final cubit = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: progress ?? FakeProgressRepository(),
      onboarding: FakeOnboardingRepository(onboarding),
      characters: FakeCharacterRepository(),
      rating: FakeRatingRepository(),
      lessons: FakeLessonRepository(),
      school: FakeSchoolProgressRepository(),
      profile: FakeProfileRepository(const UserProfile()),
      endgameLessons: FakeEndgameLessonRepository(),
      endgameProgress: FakeEndgameProgressRepository(),
      homeLayout: FakeHomeLayoutRepository(),
      now: now ?? FakeNow(day1),
      activity: activity,
      positions: FakePositionsRepository(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('cargas ao mesmo tempo (Gap 2)', () {
    test('a mais velha termina depois: vale a mais nova', () async {
      final progress = _GatedProgress();
      final home = cubit(progress: progress);
      final first = home.load();
      await Future<void>.delayed(Duration.zero);
      // A segunda carga já viu o que o jogador cumpriu depois.
      await progress.addAttempt(
        Attempt(
          positionId: 'basic.queen.0001',
          challengeId: 'c1',
          playedAt: day1,
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          opponentLevel: 1000,
        ),
      );
      await home.load();
      expect(home.state.journeyStarted, isTrue);
      // A primeira (lenta) acaba com a leitura antiga: não pode sobrescrever.
      progress.firstRead.complete(<String>{});
      await first;
      expect(home.state.journeyStarted, isTrue);
    });

    test('a mais velha falha depois de a nova pronta: não derruba', () async {
      final progress = _GatedProgress();
      final home = cubit(progress: progress);
      final first = home.load();
      await Future<void>.delayed(Duration.zero);
      await home.load();
      progress.firstRead.completeError(StateError('lento e quebrado'));
      await first;
      expect(home.state.ready, isTrue);
      expect(home.state.failed, isFalse);
    });
  });

  test('dia novo ao voltar do segundo plano (Gap 3)', () async {
    final now = FakeNow(day1);
    final activity = FakeActivityRepository(
      days: {DateTime(2026, 10, 21), day1},
      now: now,
    );
    final home = cubit(now: now, activity: activity);
    await home.load();
    expect(home.state.streak.activeToday, isTrue);
    expect(home.state.streak.current, 2);
    // O app volta do segundo plano dois dias depois, sem ter jogado.
    now.advance(const Duration(days: 2));
    await home.load();
    expect(home.state.streak.activeToday, isFalse);
    expect(home.state.streak.current, 0);
    expect(home.state.streak.lost, 2);
  });

  group('na tela', () {
    late GoRouter router;
    late HomeCubit home;

    Future<void> open(
      WidgetTester tester, {
      Onboarding onboarding = const Onboarding(done: true),
    }) async {
      tester.view
        ..physicalSize = const Size(400, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      home = cubit(onboarding: onboarding);
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
                BlocProvider.value(value: home),
                // A primeira carga já com a tela escutando, como no roteador.
                BlocProvider<_FirstLoad>(
                  lazy: false,
                  create: (_) => _FirstLoad(home),
                ),
              ],
              // Como no roteador: recarrega ao voltar e do segundo plano.
              child: Builder(
                builder: (context) => ReloadOnReturn(
                  onResume: true,
                  onReturn: () => unawaited(home.load('pt')),
                  child: const HomeScreen(),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/outra',
            builder: (_, _) => const Scaffold(body: Text('outra tela')),
          ),
          GoRoute(
            path: '/tour',
            builder: (_, _) => const Scaffold(body: Text('tour')),
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
    }

    testWidgets('tour pendente com outra tela por cima: espera e abre ao '
        'voltar ao Início (Gap 4)', (tester) async {
      await open(
        tester,
        onboarding: const Onboarding(stage: OnboardingStage.tour),
      );
      // A carga ainda não terminou e um link abre outra tela por cima.
      unawaited(router.push('/outra'));
      await tester.pumpAndSettle();
      expect(home.state.ready, isTrue);
      expect(home.state.tourPending, isTrue);
      expect(find.text('outra tela'), findsOneWidget);
      expect(find.text('tour'), findsNothing);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('tour'), findsOneWidget);
    });

    testWidgets('tour pendente com o Início no topo: abre na hora', (
      tester,
    ) async {
      await open(
        tester,
        onboarding: const Onboarding(stage: OnboardingStage.tour),
      );
      await tester.pumpAndSettle();
      expect(find.text('tour'), findsOneWidget);
    });

    testWidgets('voltar de outra tela recarrega sem passar pelo esqueleto', (
      tester,
    ) async {
      await open(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.loading), findsNothing);
      unawaited(router.push('/outra'));
      await tester.pumpAndSettle();
      router.pop();
      // Logo na volta: o conteúdo antigo segue, sem esqueleto.
      await tester.pump();
      expect(find.byKey(HomeKeys.loading), findsNothing);
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.loading), findsNothing);
    });

    testWidgets('voltar do segundo plano recarrega o Início', (tester) async {
      await open(tester);
      await tester.pumpAndSettle();
      final before = home.state;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(identical(home.state, before), isFalse);
      expect(home.state.ready, isTrue);
    });

    testWidgets('voltar do segundo plano com outra tela por cima: não '
        'recarrega o Início', (tester) async {
      await open(tester);
      await tester.pumpAndSettle();
      unawaited(router.push('/outra'));
      await tester.pumpAndSettle();
      final before = home.state;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(identical(home.state, before), isTrue);
    });
  });
}
