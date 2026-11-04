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
  static const _legacyStepKey = 'tour.step';
  static const _v2StepKey = 'tour.stepV2';
  static const _stepKey = 'tour.stepV3';

  /// No tour antigo (12 passos), do índice 12 em diante vinham o nível e os
  /// caminhos: no tour novo, é o passo Nível.
  static const _legacyLevelIndex = 12;

  /// Índices do tour novo: tabuleiro 0, tema 1, voz 2, nível 3, região 4,
  /// conta 5.
  static const _voiceStep = 2;
  static const _levelStep = 3;
  static const _startRungKey = 'journey.startRung';
  static const _ratingKey = 'tour.selectedRating';
  static const _byHandKey = 'tour.byHand';
  static const _inProgressKey = 'tour.inProgress';
  static const _linkSetupKey = 'tour.linkSetupDone';
  static const _legacyStageKey = 'tour.stage';
  static const _stageKey = 'tour.stageV3';
  static const _controlsKey = 'tour.boardControlsDone';
  static const _controlsOpenKey = 'tour.boardControlsOpen';
  static const _controlsFenKey = 'tour.boardControlsFen';

  final PreferencesService _preferences;

  Future<OnboardingStage> _stage() async {
    final saved = await _preferences.getString(_stageKey);
    if (saved != null) {
      return OnboardingStage.fromCode(saved) ?? OnboardingStage.goal;
    }
    // Etapa antiga: "tour" e "level" já passaram pelo tour; "goal" ainda
    // não escolheu o objetivo.
    final legacy = await _preferences.getString(_legacyStageKey);
    if (legacy == 'tour' || legacy == 'level') return OnboardingStage.tour;
    if (legacy != null) return OnboardingStage.goal;
    final hasTour =
        await _preferences.getBool(_inProgressKey) == true ||
        await _preferences.getString(_v2StepKey) != null ||
        await _preferences.getString(_legacyStepKey) != null;
    return hasTour ? OnboardingStage.tour : OnboardingStage.goal;
  }

  /// O passo salvo. Sem a chave nova, vem das antigas: do V2 (voz 1 vira 2;
  /// escola, ajuda e jogar viram o Nível) ou do tour de 12 passos (índice 12
  /// em diante é o Nível). A etapa antiga "level" também leva ao Nível. A
  /// chave nova é gravada e as antigas apagadas.
  Future<int> _loadStep() async {
    final saved = int.tryParse(await _preferences.getString(_stepKey) ?? '');
    if (saved != null) return saved;
    final v2 = int.tryParse(await _preferences.getString(_v2StepKey) ?? '');
    final legacy = int.tryParse(
      await _preferences.getString(_legacyStepKey) ?? '',
    );
    final legacyStage = await _preferences.getString(_legacyStageKey);
    int? step;
    if (v2 != null) {
      step = v2 <= 0 ? 0 : (v2 == 1 ? _voiceStep : _levelStep);
    } else if (legacy != null) {
      step = legacy >= _legacyLevelIndex ? _levelStep : 0;
    }
    if (legacyStage == 'level') step = _levelStep;
    if (step == null) return 0;
    await _preferences.setString(_stepKey, step.toString());
    await _preferences.remove(_v2StepKey);
    await _preferences.remove(_legacyStepKey);
    return step;
  }

  @override
  Future<Onboarding> load() async => Onboarding(
    step: await _loadStep(),
    selectedRating: int.tryParse(
      await _preferences.getString(_ratingKey) ?? '',
    ),
    byHand: await _preferences.getBool(_byHandKey) ?? false,
    inProgress: await _preferences.getBool(_inProgressKey) ?? false,
    linkSetupDone: await _preferences.getBool(_linkSetupKey) ?? false,
    // Sem a chave (antes da E1.11): o tour, que leva às telas seguintes.
    stage: await _stage(),
    boardControlsDone: await _preferences.getBool(_controlsKey) ?? false,
    boardControlsOpen: await _preferences.getBool(_controlsOpenKey) ?? false,
    boardControlsFen: await _preferences.getString(_controlsFenKey),
    done: await _preferences.getBool(_doneKey) ?? false,
    startRung: await _preferences.getString(_startRungKey),
  );

  @override
  Future<void> save(Onboarding onboarding) async {
    // Choice first: a cold resume must not see a later step/done without it.
    final rating = onboarding.selectedRating;
    if (rating == null) {
      await _preferences.remove(_ratingKey);
    } else {
      await _preferences.setString(_ratingKey, rating.toString());
    }
    await _preferences.setBool(_byHandKey, value: onboarding.byHand);
    await _preferences.setBool(_inProgressKey, value: onboarding.inProgress);
    await _preferences.setBool(_linkSetupKey, value: onboarding.linkSetupDone);
    await _preferences.setString(_stageKey, onboarding.stage.name);
    await _preferences.setBool(
      _controlsKey,
      value: onboarding.boardControlsDone,
    );
    await _preferences.setBool(
      _controlsOpenKey,
      value: onboarding.boardControlsOpen,
    );
    if (onboarding.boardControlsFen != null) {
      await _preferences.setString(
        _controlsFenKey,
        onboarding.boardControlsFen!,
      );
    }
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
