import '../../../domain/models/onboarding.dart';
import '../../services/preferences_service.dart';

/// O tour da primeira abertura.
abstract class OnboardingRepository {
  Future<Onboarding> load();

  Future<void> save(Onboarding onboarding);
}

/// Gravado nas preferências do aparelho.
class LocalOnboardingRepository implements OnboardingRepository {
  LocalOnboardingRepository(this._preferences);

  static const _doneKey = 'tour.done';
  static const _stepKey = 'tour.step';
  static const _startRungKey = 'journey.startRung';

  final PreferencesService _preferences;

  @override
  Future<Onboarding> load() async => Onboarding(
    done: await _preferences.getBool(_doneKey) ?? false,
    step: int.tryParse(await _preferences.getString(_stepKey) ?? '') ?? 0,
    startRung: await _preferences.getString(_startRungKey),
  );

  @override
  Future<void> save(Onboarding onboarding) async {
    await _preferences.setBool(_doneKey, value: onboarding.done);
    await _preferences.setString(_stepKey, onboarding.step.toString());
    final startRung = onboarding.startRung;
    if (startRung == null) {
      await _preferences.remove(_startRungKey);
    } else {
      await _preferences.setString(_startRungKey, startRung);
    }
  }
}
