import 'dart:async';

import '../../data/repositories/achievements/achievements_repository_local.dart';
import '../../data/repositories/activity/activity_repository.dart';
import '../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../data/repositories/endgames/endgame_progress_repository_notifying.dart';
import '../../data/repositories/featured/featured_progress_repository.dart';
import '../../data/repositories/journey/journey_repository_asset.dart';
import '../../data/repositories/learning/learning_content_version.dart';
import '../../data/repositories/learning/learning_repository.dart';
import '../../data/repositories/maia/maia_repository.dart';
import '../../data/repositories/onboarding/onboarding_repository.dart';
import '../../data/repositories/profile/profile_repository_local.dart';
import '../../data/repositories/progress/progress_repository_local.dart';
import '../../data/repositories/progress/progress_repository_restored.dart';
import '../../data/repositories/race/race_repository_local.dart';
import '../../data/repositories/rating/rating_repository_local.dart';
import '../../data/repositories/school/school_progress_repository.dart';
import '../../data/repositories/school/star_challenge_repository.dart';
import '../../data/repositories/speedrun/speedrun_repository_local.dart';
import '../../data/repositories/sync/sync_repository.dart';
import '../../domain/models/learning_unit_completion.dart';
import 'content.dart';
import 'core.dart';

/// O perfil, o progresso gravado no aparelho e a cópia dele na conta.
class ProgressDependencies {
  ProgressDependencies._({
    required this.changes,
    required this.profile,
    required this.progress,
    required this.learning,
    required this.activity,
    required this.journey,
    required this.speedruns,
    required this.race,
    required this.rating,
    required this.achievements,
    required this.onboarding,
    required this.school,
    required this.stars,
    required this.endgames,
    required this.featured,
  });

  /// [onUnitCompleted] leva a unidade terminada ao treino do dia, montado
  /// depois deste progresso.
  factory ProgressDependencies.create(
    CoreDependencies core,
    ContentDependencies content, {
    required MaiaRepository maia,
    required Future<void> Function(LearningUnitCompletion) onUnitCompleted,
  }) {
    final now = core.now;
    final preferences = core.preferences;
    final database = core.database;
    final profile = LocalProfileRepository(database);
    // Partida ou aula gravada: a conta recebe o progresso pouco depois.
    final changes = StreamController<void>.broadcast();
    final progress = RestoredProgressRepository(
      LocalProgressRepository(database),
      preferences,
      onAdded: () => changes.add(null),
    );
    final learning = LearningRepository(
      preferences,
      now,
      currentUid: core.uid,
      versionOf: LearningContentVersion(content.lessonContent).call,
      onChanged: () => changes.add(null),
      onUnitCompleted: onUnitCompleted,
    );
    final activity = LocalActivityRepository(preferences, progress, now);
    // Capítulo terminado: também é dia com atividade (decisão 2b da E1.22).
    void changed() {
      changes.add(null);
      unawaited(activity.markToday());
    }

    return ProgressDependencies._(
      changes: changes,
      profile: profile,
      progress: progress,
      learning: learning,
      activity: activity,
      journey: AssetJourneyRepository(core.assets, content.positions),
      speedruns: LocalSpeedrunRepository(database),
      race: LocalRaceRepository(core.assets, preferences, now),
      rating: LocalRatingRepository(
        database,
        maia: maia,
        profile: profile,
        now: now,
      ),
      achievements: LocalAchievementsRepository(core.assets, database),
      onboarding: LocalOnboardingRepository(preferences),
      school: ActiveSchoolProgressRepository(
        LocalSchoolProgressRepository(preferences),
        activity,
      ),
      stars: LocalStarChallengeRepository(preferences),
      endgames: NotifyingEndgameProgressRepository(
        LocalEndgameProgressRepository(preferences),
        changed,
      ),
      featured: ActiveFeaturedProgressRepository(
        LocalFeaturedProgressRepository(preferences),
        activity,
      ),
    );
  }

  /// Avisa que o aparelho gravou progresso (partida ou aula terminada).
  final StreamController<void> changes;
  final LocalProfileRepository profile;
  final RestoredProgressRepository progress;
  final LearningRepository learning;
  final LocalActivityRepository activity;
  final AssetJourneyRepository journey;
  final LocalSpeedrunRepository speedruns;
  final LocalRaceRepository race;
  final LocalRatingRepository rating;
  final LocalAchievementsRepository achievements;
  final LocalOnboardingRepository onboarding;
  final ActiveSchoolProgressRepository school;
  final LocalStarChallengeRepository stars;
  final NotifyingEndgameProgressRepository endgames;
  final ActiveFeaturedProgressRepository featured;

  /// O progresso na conta (E1.13).
  CloudSyncRepository sync(CoreDependencies core) => CloudSyncRepository(
    learning: learning,
    store: core.cloudStore,
    preferences: core.preferences,
    now: core.now,
    profile: profile,
    rating: rating,
    progress: progress,
    endgames: endgames,
    school: school,
    stars: stars,
    onboarding: onboarding,
    journey: journey,
    speedruns: speedruns,
    race: race,
    featured: featured,
  );
}
