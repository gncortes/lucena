import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/core/keys/tour_keys.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';
import 'package:lucena/ui/tour/widgets/tour_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('os passos em ordem e o nível no fim, em português', (
    tester,
  ) async {
    final onboarding = FakeOnboardingRepository(const Onboarding());
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider(
          create: (_) => TourCubit(
            onboarding: onboarding,
            profile: FakeProfileRepository(),
            characters: FakeCharacterRepository(),
            lessons: FakeLessonRepository(),
          )..load('pt'),
          child: const TourScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(TourKeys.step(TourStep.goal)), findsOneWidget);
    expect(find.byKey(TourKeys.skipButton), findsOneWidget);
    for (var step = 1; step < TourStep.values.length; step++) {
      await tester.tap(find.byKey(TourKeys.nextButton));
      await tester.pumpAndSettle();
      expect(find.byKey(TourKeys.step(TourStep.values[step])), findsOneWidget);
    }
    expect(find.text('Qual é o seu nível atual?'), findsOneWidget);
    await tester.tap(find.byKey(TourKeys.level(RatingLevel.advanced)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(TourKeys.startRung), 100);
    expect(find.text('A Jornada começa no Maia 1800'), findsOneWidget);
    expect(find.byKey(TourKeys.startButton), findsOneWidget);
    expect(find.byKey(TourKeys.skipButton), findsNothing);

    // Iniciante: o botão abre as aulas.
    await tester.ensureVisible(
      find.byKey(TourKeys.level(RatingLevel.beginner)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TourKeys.level(RatingLevel.beginner)));
    await tester.pumpAndSettle();
    expect(find.text('Começar as aulas'), findsOneWidget);
    expect(find.byKey(TourKeys.viktor), findsOneWidget);
    expect(find.text('Mestre Viktor'), findsOneWidget);
  });
}
