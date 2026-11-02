import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/goal/view_models/goal_cubit.dart';
import 'package:lucena/ui/goal/widgets/goal_screen.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/level/widgets/level_screen.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/tour/widgets/tour_screen.dart';
import 'package:lucena/ui/board_controls/view_models/board_controls_cubit.dart';
import 'package:lucena/ui/board_controls/widgets/board_controls_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';
import '../../../testing/fakes/fake_chesscom_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

class _FailingOnboarding extends FakeOnboardingRepository {
  _FailingOnboarding() : super(const Onboarding(inProgress: true));
  bool failing = true;
  bool saveFailing = false;
  @override
  Future<Onboarding> load() async {
    if (failing) throw StateError('database');
    return super.load();
  }

  @override
  Future<void> save(Onboarding onboarding) async {
    if (saveFailing) throw StateError('database write');
    await super.save(onboarding);
  }
}

void main() {
  for (final area in ['tour', 'goal', 'level', 'board_controls']) {
    for (final saveFailure in [false, true]) {
      testWidgets('$area ${saveFailure ? 'write' : 'read'} failure and retry', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repository = _FailingOnboarding()
          ..failing = !saveFailure
          ..saveFailing = saveFailure;
        final settings = SettingsCubit(
          FakeSettingsRepository(),
          languages: const [AppLanguage.english],
        );
        addTearDown(settings.close);
        final profile = FakeProfileRepository();
        final characters = FakeCharacterRepository();
        late Widget screen;
        late Future<void> Function() load;
        final Widget provider;
        switch (area) {
          case 'tour':
            final cubit = TourCubit(
              onboarding: repository,
              profile: profile,
              characters: characters,
              lessons: FakeLessonRepository(),
            );
            addTearDown(cubit.close);
            load = () => cubit.load('pt');
            screen = const TourScreen();
            provider = BlocProvider.value(value: cubit, child: screen);
          case 'goal':
            final cubit = GoalCubit(
              onboarding: repository,
              profile: profile,
              characters: characters,
            );
            addTearDown(cubit.close);
            load = cubit.load;
            screen = const GoalScreen();
            provider = BlocProvider.value(value: cubit, child: screen);
          case 'level':
            final cubit = LevelCubit(
              onboarding: repository,
              profile: profile,
              characters: characters,
              lichess: FakeLichessRepository(),
              chessCom: FakeChessComRepository(),
            );
            addTearDown(cubit.close);
            load = cubit.load;
            screen = const LevelScreen();
            provider = BlocProvider.value(value: cubit, child: screen);
          default:
            final cubit = BoardControlsCubit(repository);
            addTearDown(cubit.close);
            load = cubit.load;
            screen = const BoardControlsScreen();
            provider = BlocProvider.value(value: cubit, child: screen);
        }
        await load();
        await tester.pumpWidget(
          TestApp(
            locale: const Locale('pt'),
            child: BlocProvider.value(value: settings, child: provider),
          ),
        );
        await tester.pump();
        expect(
          tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
          LoadErrorKind.generic,
        );
        expect(
          find.byKey(LoadErrorKeys.back),
          area == 'board_controls' ? findsOneWidget : findsNothing,
        );
        repository.failing = false;
        repository.saveFailing = false;
        await tester.tap(find.byKey(LoadErrorKeys.action));
        await tester.pump();
        expect(find.byType(LoadErrorScreen), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
