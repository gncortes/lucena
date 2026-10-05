import 'package:lucena/config/dependencies.dart';
import 'package:lucena/data/repositories/haptics/haptics_repository.dart';
import 'package:lucena/data/repositories/journey/journey_repository.dart';
import 'package:lucena/data/repositories/speedrun/speedrun_repository.dart';
import 'package:lucena/data/repositories/ongoing_game/ongoing_game_repository.dart';
import 'package:lucena/data/repositories/maia/maia_repository.dart';
import 'package:lucena/data/repositories/opponent/opponent_repository.dart';
import 'package:lucena/data/repositories/positions/positions_repository.dart';
import 'package:lucena/data/repositories/progress/progress_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/settings/settings_repository.dart';
import 'package:lucena/data/repositories/training/training_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/data/repositories/rating/rating_repository.dart';
import 'package:lucena/data/repositories/achievements/achievements_repository.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/evaluation/evaluation_repository.dart';
import 'package:lucena/data/repositories/characters/talk_repository.dart';
import 'package:lucena/data/repositories/onboarding/onboarding_repository.dart';
import 'package:lucena/data/repositories/pace/pace_repository.dart';
import 'package:lucena/data/repositories/school/lesson_repository.dart';
import 'package:lucena/data/repositories/school/school_progress_repository.dart';

import 'fakes/fake_rating_repository.dart';
import 'fakes/fake_achievements_repository.dart';
import 'fakes/fake_character_repository.dart';
import 'fakes/fake_evaluation_repository.dart';
import 'fakes/fake_talk_repository.dart';
import 'fakes/fake_onboarding_repository.dart';
import 'fakes/fake_pace_repository.dart';
import 'fakes/fake_school_repositories.dart';

import 'fakes/fake_haptics_repository.dart';
import 'fakes/fake_journey_repository.dart';
import 'fakes/fake_speedrun_repository.dart';
import 'fakes/fake_maia_repository.dart';
import 'fakes/fake_now.dart';
import 'fakes/fake_ongoing_game_repository.dart';
import 'fakes/fake_opponent_repository.dart';
import 'fakes/fake_positions_repository.dart';
import 'fakes/fake_profile_repository.dart';
import 'fakes/fake_progress_repository.dart';
import 'fakes/fake_settings_repository.dart';
import 'fakes/fake_training_repository.dart';

/// Composição dos testes de unidade e de widget: tudo falso, nada toca o aparelho.
Dependencies testDependencies({
  FakeNow? now,
  SettingsRepository? settingsRepository,
  ProfileRepository? profileRepository,
  HapticsRepository? hapticsRepository,
  OngoingGameRepository? ongoingGameRepository,
  PositionsRepository? positionsRepository,
  TrainingRepository? trainingRepository,
  OpponentRepository? opponentRepository,
  MaiaRepository? maiaRepository,
  ProgressRepository? progressRepository,
  JourneyRepository? journeyRepository,
  SpeedrunRepository? speedrunRepository,
  RatingRepository? ratingRepository,
  AchievementsRepository? achievementsRepository,
  CharacterRepository? characterRepository,
  EvaluationRepository? evaluationRepository,
  TalkRepository? talkRepository,
  OnboardingRepository? onboardingRepository,
  PaceRepository? paceRepository,
  LessonRepository? lessonRepository,
  SchoolProgressRepository? schoolProgressRepository,
  List<AppLanguage>? languages,
}) {
  final progress = progressRepository ?? FakeProgressRepository();
  return Dependencies(
    now: now ?? FakeNow(DateTime.utc(2026, 1, 1, 12)),
    settingsRepository: settingsRepository ?? FakeSettingsRepository(),
    profileRepository: profileRepository ?? FakeProfileRepository(),
    hapticsRepository: hapticsRepository ?? FakeHapticsRepository(),
    ongoingGameRepository: ongoingGameRepository ?? FakeOngoingGameRepository(),
    positionsRepository: positionsRepository ?? FakePositionsRepository(),
    trainingRepository: trainingRepository ?? FakeTrainingRepository(),
    opponentRepository: opponentRepository ?? FakeOpponentRepository(),
    maiaRepository: maiaRepository ?? FakeMaiaRepository(),
    progressRepository: progress,
    journeyRepository: journeyRepository ?? FakeJourneyRepository(),
    speedrunRepository:
        speedrunRepository ??
        FakeSpeedrunRepository(
          progress is FakeProgressRepository
              ? progress
              : FakeProgressRepository(),
        ),
    ratingRepository: ratingRepository ?? FakeRatingRepository(),
    achievementsRepository:
        achievementsRepository ?? FakeAchievementsRepository(),
    characterRepository: characterRepository ?? FakeCharacterRepository(),
    evaluationRepository: evaluationRepository ?? FakeEvaluationRepository(),
    talkRepository: talkRepository ?? FakeTalkRepository(),
    onboardingRepository: onboardingRepository ?? FakeOnboardingRepository(),
    paceRepository: paceRepository ?? FakePaceRepository(),
    lessonRepository: lessonRepository ?? FakeLessonRepository(),
    schoolProgressRepository:
        schoolProgressRepository ?? FakeSchoolProgressRepository(),
    languages: languages ?? AppLanguage.selectable,
  );
}
