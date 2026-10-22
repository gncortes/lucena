import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/level_keys.dart';
import 'package:lucena/ui/core/keys/profile_keys.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/level/widgets/level_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeOnboardingRepository onboarding;

  Future<void> pumpLevel(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
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
    onboarding = FakeOnboardingRepository(
      const Onboarding(inProgress: true, step: 4),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => BlocProvider(
            create: (_) => LevelCubit(
              onboarding: onboarding,
              profile: FakeProfileRepository(),
              characters: FakeCharacterRepository(),
              lessons: FakeLessonRepository(
                texts: LessonTexts.fromJson({'tour.level': 'Escolha.'}),
              ),
              home: FakeHomeLayoutRepository(),
            )..load('en'),
            child: const LevelScreen(),
          ),
        ),
        GoRoute(
          path: Routes.goal,
          builder: (_, _) => const Scaffold(body: Text('rota-objetivo')),
        ),
        GoRoute(
          path: Routes.school,
          builder: (_, _) => const Scaffold(body: Text('rota-aulas')),
        ),
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

  testWidgets(
    'abre com "Fazer o teste" marcado, Continuar habilitado e cartões '
    'de 48 ou mais',
    (tester) async {
      await pumpLevel(tester);
      expect(find.text('Your level'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(LevelKeys.next)).onPressed,
        isNotNull,
      );
      expect(
        tester
            .element(find.byKey(LevelKeys.screen))
            .read<LevelCubit>()
            .state
            .choice,
        LevelChoice.test,
      );
      for (final choice in LevelChoice.values) {
        final card = find.byKey(LevelKeys.option(choice));
        await tester.ensureVisible(card);
        expect(tester.getSize(card).height, greaterThanOrEqualTo(48));
      }
    },
  );

  testWidgets('a seta de voltar leva à pergunta do objetivo', (tester) async {
    await pumpLevel(tester);
    await tester.tap(find.byKey(LevelKeys.back));
    await tester.pumpAndSettle();
    expect(find.text('rota-objetivo'), findsOneWidget);
  });

  testWidgets('"Não sei jogar" libera o Continuar, grava "começando" e leva '
      'às aulas', (tester) async {
    await pumpLevel(tester);
    expect(onboarding.saved.selectedRating, isNull);
    final beginner = find.byKey(LevelKeys.option(LevelChoice.beginner));
    await tester.ensureVisible(beginner);
    await tester.tap(beginner);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    await tester.tap(find.byKey(LevelKeys.next));
    await tester.pumpAndSettle();
    expect(onboarding.saved.selectedRating, RatingLevel.beginner.rating);
    expect(onboarding.saved.done, isTrue);
    expect(find.text('rota-aulas'), findsOneWidget);
  });

  testWidgets('a faixa escolhida pela folha marca o cartão e mostra onde a '
      'Jornada começa', (tester) async {
    await pumpLevel(tester);
    final band = find.byKey(LevelKeys.option(LevelChoice.band));
    await tester.ensureVisible(band);
    await tester.tap(band);
    await tester.pumpAndSettle();
    final option = find.byKey(ProfileKeys.levelOption(RatingLevel.expert));
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProfileKeys.levelConfirmButton));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: band,
        matching: find.textContaining('Journey starts at '),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(onboarding.saved.selectedRating, RatingLevel.expert.rating);
  });
}
