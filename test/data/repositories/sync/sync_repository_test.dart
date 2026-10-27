import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/learning/learning_repository.dart';
import 'package:lucena/domain/models/learning_record.dart';
import 'package:lucena/data/repositories/progress/progress_repository_restored.dart';
import 'package:lucena/data/repositories/sync/sync_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/models/progress_summary.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_cloud_store_service.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_featured_repositories.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_race_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../../testing/fakes/fake_star_challenge_repository.dart';

Attempt _game(String position, {String? challenge}) => Attempt(
  positionId: position,
  playedAt: DateTime.utc(2026, 10, 20, 10),
  outcome: AttemptOutcome.win,
  fulfilled: true,
  opponent: OpponentKind.maia,
  challengeId: challenge,
);

void main() {
  final now = FakeNow(DateTime.utc(2026, 10, 22, 12));
  late FakeCloudStoreService store;
  late FakeProgressRepository games;
  late RestoredProgressRepository progress;
  late FakeEndgameProgressRepository endgames;
  late FakeProfileRepository profile;
  late FakeRatingRepository rating;
  late CloudSyncRepository sync;
  late LearningRepository learning;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final preferences = PreferencesService();
    store = FakeCloudStoreService();
    games = FakeProgressRepository([_game('p1', challenge: 'c1')]);
    progress = RestoredProgressRepository(games, preferences);
    endgames = FakeEndgameProgressRepository(
      const EndgameProgress(
        lessons: {
          'lucena': EndgameLessonProgress(
            parts: {'a'},
            exercise: ExerciseCheckpoint(exerciseId: 'e1'),
          ),
        },
      ),
    );
    profile = FakeProfileRepository(const UserProfile(nickname: 'Ana'));
    rating = FakeRatingRepository();
    learning = LearningRepository(
      preferences,
      now,
      currentUid: () => 'u1',
      versionOf: (_, _) async => 'v1',
    );
    sync = CloudSyncRepository(
      learning: learning,
      store: store,
      preferences: preferences,
      now: now,
      profile: profile,
      rating: rating,
      progress: progress,
      endgames: endgames,
      school: FakeSchoolProgressRepository(),
      stars: FakeStarChallengeRepository(),
      onboarding: FakeOnboardingRepository(),
      journey: FakeJourneyRepository(),
      speedruns: FakeSpeedrunRepository(games),
      race: FakeRaceRepository(now: now),
      featured: FakeFeaturedProgressRepository(),
    );
  });

  test('a primeira vez sobe o aparelho e as partidas', () async {
    final result = await sync.sync('u1');
    await pumpEventQueue();

    expect(result.hadRemote, isFalse);
    final saved = ProgressSummary.fromJson(store.progress['u1']!);
    expect(saved.challenges, {'c1'});
    expect(saved.profile.nickname, 'Ana');
    expect(store.progress['u1']!['updatedAt'], now.value);
    expect(store.games['u1']!.keys, [
      CloudSyncRepository.gameId(games.attempts.single),
    ]);
    expect(await sync.lastSyncedAt('u1'), now.value);
  });

  test('o que veio de outro aparelho vale aqui', () async {
    store.progress['u1'] = const ProgressSummary(
      rating: PlayerRating(rating: 1700, deviation: 60),
      lessons: {
        'lucena': EndgameLessonProgress(parts: {'b'}),
      },
      challenges: {'c2'},
      positions: {'p9'},
    ).toJson();

    final result = await sync.sync('u1');

    expect(result.hadRemote, isTrue);
    expect(await progress.fulfilledChallenges(), {'c1', 'c2'});
    expect(await progress.fulfilledPositions(), {'p1', 'p9'});
    final lucena = endgames.saved.lessons['lucena']!;
    expect(lucena.parts, {'a', 'b'});
    // O exercício pela metade é deste aparelho e continua aqui.
    expect(lucena.exercise?.exerciseId, 'e1');
    expect((await rating.current()).rating, 1700);
    expect(profile.profile.nickname, 'Ana');
    // As partidas de lá não descem para o histórico.
    expect(games.attempts, hasLength(1));
  });

  test('cada partida sobe uma vez só, com o mesmo id', () async {
    await sync.sync('u1');
    await pumpEventQueue();
    games.attempts.add(_game('p2'));

    await sync.sync('u1');
    await pumpEventQueue();

    expect(store.games['u1'], hasLength(2));
    expect(store.gameWrites.values, everyElement(1));
  });

  test('sem rede, entrar falha sem mexer em nada', () async {
    store.offline = true;

    await expectLater(sync.sync('u1'), throwsA(isA<SyncException>()));
    expect(endgames.saved.lessons['lucena']!.parts, {'a'});
    expect(await sync.lastSyncedAt('u1'), isNull);
  });

  test(
    'learning survives offline and next sync merges only the requested account',
    () async {
      await learning.serial(
        () => learning.observe(
          owner: 'u1',
          version: 'v1',
          kind: 'school_lesson',
          unitId: 'x',
          started: true,
        ),
      );
      await learning.restore('u2', [
        LearningRecord(
          kind: 'school_lesson',
          unitId: 'private',
          version: 'v1',
          firstStartedAt: now(),
        ),
      ]);
      store.offline = true;
      await expectLater(sync.sync('u1'), throwsA(isA<SyncException>()));
      expect((await learning.load('u1')).single.firstStartedAt, now());
      store.offline = false;
      final old = DateTime.utc(2026, 9, 1);
      store.progress['u1'] = ProgressSummary(
        learningV1: [
          LearningRecord(
            kind: 'school_lesson',
            unitId: 'x',
            version: 'v1',
            firstStartedAt: old,
            contentCompletedAt: old,
          ),
        ],
      ).toJson();
      final result = await sync.sync('u1');
      await pumpEventQueue();
      expect(result.summary.learningV1.single.firstStartedAt, old);
      expect((await learning.load('u1')).single.contentCompletedAt, old);
      final uploaded = ProgressSummary.fromJson(store.progress['u1']!);
      expect(uploaded.learningV1.single.unitId, 'x');
      expect((await learning.load('u2')).single.unitId, 'private');
    },
  );

  test('o id da partida não depende do aparelho', () {
    final game = _game('rook/lucena 1');
    expect(
      CloudSyncRepository.gameId(game),
      '${DateTime.utc(2026, 10, 20, 10).microsecondsSinceEpoch}-rook_lucena_1',
    );
  });
}
