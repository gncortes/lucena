import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
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

class _PokableHomeCubit extends HomeCubit {
  _PokableHomeCubit({required super.now, required super.activity})
    : super(
        journey: FakeJourneyRepository(),
        progress: FakeProgressRepository(),
        onboarding: FakeOnboardingRepository(const Onboarding(done: true)),
        characters: FakeCharacterRepository(),
        rating: FakeRatingRepository(),
        lessons: FakeLessonRepository(),
        school: FakeSchoolProgressRepository(),
        profile: FakeProfileRepository(const UserProfile()),
        endgameLessons: FakeEndgameLessonRepository(),
        endgameProgress: FakeEndgameProgressRepository(),
        homeLayout: FakeHomeLayoutRepository(),
        positions: FakePositionsRepository(),
        analytics: FakeAnalyticsRepository(),
      );

  /// Um estado novo com os mesmos valores: nenhum campo lido pelo corpo muda.
  void poke() => emit(state.copyWith(streak: state.streak));
}

void main() {
  testWidgets(
    'estado novo sem mudar pronto/falha não refaz o corpo do Início',
    (tester) async {
      tester.view
        ..physicalSize = const Size(400, 1600)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final now = FakeNow(DateTime(2026, 10, 22, 9));
      final cubit = _PokableHomeCubit(
        now: now,
        activity: FakeActivityRepository(days: const {}, now: now),
      )..load();
      addTearDown(cubit.close);
      final router = GoRouter(
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
                BlocProvider<HomeCubit>.value(value: cubit),
              ],
              child: const HomeScreen(),
            ),
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

      final before = tester.widget<EntradaDaTela>(find.byType(EntradaDaTela));
      cubit.poke();
      await tester.pumpAndSettle();
      final after = tester.widget<EntradaDaTela>(find.byType(EntradaDaTela));

      expect(identical(after, before), isTrue);
    },
  );
}
