import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';

import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeProfileRepository profile;

  TourCubit cubit() {
    final cubit = TourCubit(onboarding: onboarding, profile: profile);
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    onboarding = FakeOnboardingRepository(const Onboarding());
    profile = FakeProfileRepository();
  });

  test('cada passo é gravado e volta ao reabrir', () async {
    final tour = cubit();
    await tour.load();
    await tour.next();
    await tour.next();

    final reopened = cubit();
    await reopened.load();
    expect(reopened.state.step, TourStep.journey);
  });

  test('escolher 1400 no fim: perfil e degrau de início', () async {
    final tour = cubit();
    await tour.load();
    for (var step = 0; step < TourStep.values.length - 1; step++) {
      await tour.next();
    }
    expect(tour.state.step, TourStep.level);
    tour.setLevel(RatingLevel.intermediate);
    expect(tour.state.startRung, '1400');
    await tour.finish();

    expect(tour.state.finished, isTrue);
    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.startRung, '1400');
    expect((await profile.load()).level, RatingLevel.intermediate);
  });

  test('pular: o tour não aparece de novo e o degrau não muda', () async {
    final tour = cubit();
    await tour.load();
    await tour.skip();

    expect(onboarding.saved.done, isTrue);
    expect(onboarding.saved.startRung, isNull);
  });

  test('rever o tour já visto começa do primeiro passo', () async {
    onboarding.saved = const Onboarding(done: true, step: 5);
    final tour = cubit();
    await tour.load();
    expect(tour.state.step, TourStep.goal);
  });

  test('iniciante começa no Maia 1000', () async {
    final tour = cubit();
    await tour.load();
    tour.setLevel(RatingLevel.beginner);
    expect(tour.state.startRung, '1000');
  });
}
