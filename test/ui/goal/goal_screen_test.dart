import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/goal_keys.dart';
import 'package:lucena/ui/goal/view_models/goal_cubit.dart';
import 'package:lucena/ui/goal/widgets/goal_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeProfileRepository profile;

  Future<void> pumpGoal(
    WidgetTester tester, {
    Size size = const Size(412, 915),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final speech = SpeechCubit(
      FakeVoiceRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(speech.close);
    await speech.load();
    final settingsCubit = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settingsCubit.close);
    await settingsCubit.load();
    profile = FakeProfileRepository();
    Widget route(String text) => Scaffold(body: Text(text));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => BlocProvider(
            create: (_) => GoalCubit(
              onboarding: FakeOnboardingRepository(
                const Onboarding(inProgress: true),
              ),
              profile: profile,
              characters: FakeCharacterRepository(),
              home: FakeHomeLayoutRepository(),
            )..load(),
            child: const GoalScreen(),
          ),
        ),
        GoRoute(path: Routes.level, builder: (_, _) => route('rota-nivel')),
        GoRoute(path: Routes.tour, builder: (_, _) => route('rota-tour')),
        GoRoute(
          path: Routes.accountEnter,
          builder: (_, _) => route('rota-conta'),
        ),
        GoRoute(path: Routes.school, builder: (_, _) => route('rota-aulas')),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settingsCubit,
        speechCubit: speech,
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(412, 915), Size(360, 640)]) {
    testWidgets('a fala, os três cartões e o rodapé (${size.width.toInt()})', (
      tester,
    ) async {
      await pumpGoal(tester, size: size);
      expect(find.byKey(GoalKeys.speech), findsOneWidget);
      expect(find.text('What do you want to do?'), findsOneWidget);
      for (final goal in GoalPreference.values) {
        final card = find.byKey(GoalKeys.option(goal));
        await tester.ensureVisible(card);
        expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      }
      expect(find.byKey(GoalKeys.continueButton), findsOneWidget);
      expect(find.byKey(GoalKeys.haveAccount), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Continuar com um objetivo de finais vai para o nível', (
    tester,
  ) async {
    await pumpGoal(tester);
    await tester.tap(find.byKey(GoalKeys.option(GoalPreference.train)));
    await tester.pump();
    await tester.tap(find.byKey(GoalKeys.continueButton));
    await tester.pumpAndSettle();
    expect(find.text('rota-nivel'), findsOneWidget);
    expect(profile.profile.goal, GoalPreference.train);
  });

  testWidgets('aprender a jogar pula o nível', (tester) async {
    await pumpGoal(tester);
    await tester.tap(find.byKey(GoalKeys.option(GoalPreference.learn)));
    await tester.pump();
    await tester.tap(find.byKey(GoalKeys.continueButton));
    await tester.pumpAndSettle();
    expect(find.text('rota-nivel'), findsNothing);
    expect(profile.profile.goal, GoalPreference.learn);
  });

  testWidgets('a seta de voltar leva ao tour', (tester) async {
    await pumpGoal(tester);
    await tester.tap(find.byKey(GoalKeys.back));
    await tester.pumpAndSettle();
    expect(find.text('rota-tour'), findsOneWidget);
  });

  testWidgets('"Já tenho conta" abre a conta', (tester) async {
    await pumpGoal(tester);
    await tester.tap(find.byKey(GoalKeys.haveAccount));
    await tester.pumpAndSettle();
    expect(find.text('rota-conta'), findsOneWidget);
  });
}
