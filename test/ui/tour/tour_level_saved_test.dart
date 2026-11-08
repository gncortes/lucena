import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/level/view_models/level_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_chesscom_repository.dart';
import '../../../testing/fakes/fake_lichess_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';

/// O passo Nível grava o degrau da Jornada e o rating escolhido; o passo
/// seguinte do tour (e o fim dele) não pode apagá-los com uma cópia antiga.
void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;

  setUp(() {
    onboarding = FakeOnboardingRepository(
      const Onboarding(stage: OnboardingStage.tour),
    );
    profile = FakeProfileRepository(
      const UserProfile(goal: GoalPreference.train),
    );
  });

  Future<(TourCubit, LevelCubit)> toLevelStep() async {
    final tour = TourCubit(
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
    );
    addTearDown(tour.close);
    await tour.load('pt');
    while (tour.state.step != TourStep.level) {
      await tour.next();
    }
    final level = LevelCubit(
      onboarding: onboarding,
      profile: profile,
      characters: FakeCharacterRepository(),
      lichess: FakeLichessRepository(),
      chessCom: FakeChessComRepository(),
      inTour: true,
    );
    addTearDown(level.close);
    await level.load();
    return (tour, level);
  }

  test('a faixa escolhida sobrevive a "Continuar" e ao fim do tour', () async {
    final (tour, level) = await toLevelStep();
    level.selectBand(RatingLevel.casual);
    await level.finish();
    final expected = onboarding.saved;
    expect(expected.startRung, isNotNull);
    expect(expected.selectedRating, 1150);

    await tour.next();
    await tour.next();
    expect(tour.state.step, TourStep.account);
    await tour.finish(leave: false);

    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.startRung, expected.startRung);
    expect(onboarding.saved.selectedRating, 1150);
    expect(onboarding.saved.byHand, isTrue);
    expect(profile.profile.rating, 1150);
    expect(profile.profile.goal, GoalPreference.train);
  });
}
