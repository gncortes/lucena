import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';
import 'package:lucena/ui/endgames/widgets/endgame_lesson_screen.dart';
import 'package:lucena/ui/endgames/widgets/endgame_info_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercises_intro_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercises_done_screen.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/school/view_models/school_cubit.dart';
import 'package:lucena/ui/school/widgets/school_screen.dart';

import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  for (final screen in <Widget>[
    const EndgameLessonScreen(),
    const EndgameInfoScreen(),
    const ExercisesIntroScreen(),
    const ExercisesDoneScreen(),
  ]) {
    testWidgets('${screen.runtimeType} initial load has shimmer', (
      tester,
    ) async {
      final cubit = EndgameLessonCubit(
        lessons: FakeEndgameLessonRepository(),
        progress: FakeEndgameProgressRepository(),
        journey: FakeJourneyRepository(),
        characters: FakeCharacterRepository(),
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: BlocProvider.value(value: cubit, child: screen),
        ),
      );
      expect(find.byType(SkeletonBlock), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('EndgamesScreen initial load has shimmer', (tester) async {
    final cubit = EndgamesCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const EndgamesScreen()),
      ),
    );
    expect(find.byType(SkeletonBlock), findsWidgets);
  });
  testWidgets('SchoolScreen initial load has shimmer', (tester) async {
    final cubit = SchoolCubit(
      lessons: FakeLessonRepository(),
      progress: FakeSchoolProgressRepository(),
      characters: FakeCharacterRepository(),
      profile: FakeProfileRepository(),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const SchoolScreen()),
      ),
    );
    expect(find.byType(SkeletonBlock), findsWidgets);
  });
  testWidgets('ExerciseScreen without preview has shimmer', (tester) async {
    final cubit = ExerciseCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    expect(find.byType(SkeletonBlock), findsWidgets);
    // Regra da app bar (T85): a estrela já está lá no carregando, apagada.
    final star = find.descendant(
      of: find.byType(AppBar),
      matching: find.byKey(ExerciseKeys.stars),
    );
    expect(star, findsOneWidget);
    expect(
      tester.widget<Icon>(star).color,
      Theme.of(tester.element(star)).colorScheme.onSurface
          .withValues(alpha: 0.38),
    );
  });
}
