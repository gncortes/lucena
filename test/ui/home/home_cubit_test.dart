import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';

void main() {
  HomeCubit cubit({Onboarding onboarding = const Onboarding(done: true)}) {
    final cubit = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: FakeProgressRepository(),
      onboarding: FakeOnboardingRepository(onboarding),
      characters: FakeCharacterRepository(),
      rating: FakeRatingRepository(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('onde estou, contra quem e o próximo desafio', () async {
    final home = cubit();
    await home.load();

    expect(home.state.current!.rung.id, '1000');
    expect(home.state.next, sampleLadder.first.challenges.first);
    expect(home.state.character!.name, 'Coco');
    expect(home.state.rating, 1150);
    expect(home.state.tourPending, isFalse);
  });

  test('primeira abertura: o tour está pendente', () async {
    final home = cubit(onboarding: const Onboarding());
    await home.load();
    expect(home.state.tourPending, isTrue);
  });

  test('com o degrau escolhido no tour, a Jornada começa nele', () async {
    final home = cubit(
      onboarding: const Onboarding(done: true, startRung: '1200'),
    );
    await home.load();
    expect(home.state.current!.rung.id, '1200');
  });
}
