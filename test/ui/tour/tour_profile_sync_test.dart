import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/tour/view_models/tour_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';

/// Achado A1 da simulação em dev (b08): o tour grava o nome e a região
/// direto no repositório, mas o `ProfileCubit` do app (lido uma vez na
/// abertura) seguia com o perfil vazio até fechar o app. "Seu perfil" e a
/// partida mostravam "Jogador" logo depois de criar a conta.
void main() {
  test('nome e região do tour chegam ao perfil do app na hora', () async {
    final repository = FakeProfileRepository(const UserProfile(country: 'BR'));
    final profile = ProfileCubit(repository);
    addTearDown(profile.close);
    await profile.load();
    expect(profile.state?.nickname, isEmpty);

    final tour = TourCubit(
      onboarding: FakeOnboardingRepository(const Onboarding()),
      profile: repository,
      characters: FakeCharacterRepository(),
    );
    addTearDown(tour.close);
    await tour.load('pt', phoneCountry: 'BR');
    await tour.setNickname('Bruno');
    while (tour.state.step != TourStep.region) {
      await tour.next();
    }
    tour.setRegionState('SP');
    tour.setRegionCity('São Paulo');
    await tour.next();
    await pumpEventQueue();

    expect(profile.state?.nickname, 'Bruno');
    expect(profile.state?.state, 'SP');
    expect(profile.state?.city, 'São Paulo');
  });
}
