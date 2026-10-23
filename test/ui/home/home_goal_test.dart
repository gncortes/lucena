import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

/// E1.11: o objetivo do perfil põe o primeiro cartão da tela inicial.
void main() {
  late FakeProgressRepository progress;
  late FakeEndgameProgressRepository endgames;
  final now = FakeNow(DateTime(2026, 10, 22, 15));

  setUp(() {
    progress = FakeProgressRepository();
    endgames = FakeEndgameProgressRepository();
  });

  Future<HomeState> load(GoalPreference? goal, {int rating = 1150}) async {
    final cubit = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: progress,
      onboarding: FakeOnboardingRepository(),
      characters: FakeCharacterRepository(),
      rating: FakeRatingRepository(),
      lessons: FakeLessonRepository(),
      school: FakeSchoolProgressRepository(),
      profile: FakeProfileRepository(
        UserProfile(nickname: 'Ana', rating: rating, goal: goal),
      ),
      endgameLessons: FakeEndgameLessonRepository(),
      endgameProgress: endgames,
      homeLayout: FakeHomeLayoutRepository(),
      positions: FakePositionsRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit.state;
  }

  Future<void> playJourney() => progress.addAttempt(
    Attempt(
      positionId: sampleLadder.first.challenges.first.position.id,
      challengeId: sampleLadder.first.challenges.first.id,
      playedAt: now(),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      opponentLevel: 1000,
    ),
  );

  test('sem objetivo, a tela fica como era', () async {
    final state = await load(null);

    expect(state.goalPath, isNull);
    expect(state.resumePath, isNull);
    expect(state.continuePath, isNotNull);
    expect(state.shownPaths, state.layout!.shown);
  });

  test(
    'aprender finais: a primeira aula da trilha, com o lugar dela',
    () async {
      final state = await load(GoalPreference.endgames);

      expect(state.goalPath, HomePath.endgames);
      final goal = state.endgameGoal!;
      expect(goal.lesson.lessonId, 'rook.lucena');
      expect((goal.number, goal.total, goal.passed), (1, 2, 0));
      expect(state.continuePath, isNull);
      expect(state.shownPaths, isNot(contains(HomePath.endgames)));
      expect(state.shownPaths, contains(HomePath.forYou));
    },
  );

  test('aprender finais: a aula começada é a do cartão', () async {
    endgames = FakeEndgameProgressRepository(
      const EndgameProgress(
        lessons: {
          'rook.philidor': EndgameLessonProgress(stars: {'e01': 0}),
        },
      ),
    );
    final state = await load(GoalPreference.endgames);

    expect(state.endgameGoal!.lesson.lessonId, 'rook.philidor');
    expect(state.endgameGoal!.number, 2);
  });

  test('aprender finais: a Jornada com progresso vira o "continuar"', () async {
    expect((await load(GoalPreference.endgames)).resumePath, isNull);

    await playJourney();
    expect((await load(GoalPreference.endgames)).resumePath, HomePath.journey);
  });

  test('treinar finais: o final da faixa e a posição por cumprir', () async {
    final state = await load(GoalPreference.train);

    expect(state.goalPath, HomePath.train);
    final train = state.trainGoal!;
    expect(train.suggestion.subcategory.key, 'queen');
    expect((train.suggestion.done, train.suggestion.total), (0, 1));
    expect(train.fen, samplePositions.first.fen);
    expect(state.shownPaths, isNot(contains(HomePath.train)));
  });

  test(
    'treinar finais: a aula de final em andamento vira o "continuar"',
    () async {
      expect((await load(GoalPreference.train)).resumePath, isNull);

      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          lessons: {
            'rook.lucena': EndgameLessonProgress(stars: {'e01': 1}),
          },
        ),
      );
      final state = await load(GoalPreference.train);
      expect(state.resumePath, HomePath.endgames);
      expect(state.endgame!.lessonId, 'rook.lucena');
    },
  );

  test('aprender a jogar sem a Escola: a Jornada, sem "continuar"', () async {
    await playJourney();
    final state = await load(GoalPreference.learn, rating: 800);

    expect(state.goalPath, HomePath.journey);
    expect(state.resumePath, isNull);
    expect(state.shownPaths, isNot(contains(HomePath.journey)));
  });
}
