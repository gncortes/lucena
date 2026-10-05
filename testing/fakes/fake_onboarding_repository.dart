import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/domain/models/onboarding.dart';

/// Por padrão o tour já foi visto: as outras telas abrem direto.
class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository([this.saved = const Onboarding(done: true)]);

  Onboarding saved;

  @override
  Future<Onboarding> load() async => saved;

  @override
  Future<void> save(Onboarding onboarding) async => saved = onboarding;
}
