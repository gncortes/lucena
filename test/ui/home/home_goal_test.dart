import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/goal_preference.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/home_shortcut.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/player_rating.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
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

  Future<HomeState> load(
    GoalPreference? goal, {
    int rating = 1150,
    EndgameTrail? trail,
    FakeRatingRepository? ratings,
    FakePlacementRepository? placement,
    FakeSchoolProgressRepository? schoolProgress,
  }) async {
    final cubit = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: progress,
      onboarding: FakeOnboardingRepository(
        const Onboarding(done: true, boardControlsDone: true),
      ),
      characters: FakeCharacterRepository(),
      rating: ratings ?? FakeRatingRepository(),
      lessons: FakeLessonRepository(),
      school: schoolProgress ?? FakeSchoolProgressRepository(),
      profile: FakeProfileRepository(
        UserProfile(nickname: 'Ana', rating: rating, goal: goal),
      ),
      endgameLessons: FakeEndgameLessonRepository(trail: trail),
      endgameProgress: endgames,
      homeLayout: FakeHomeLayoutRepository(),
      positions: FakePositionsRepository(),
      placement: placement,
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

  test('sem objetivo: o cartão é a Jornada, também nos atalhos', () async {
    final state = await load(null);

    expect(state.hero, HomeHero.journey);
    expect(state.shortcuts.first, HomeShortcut.journey);
    expect(state.shortcuts.sublist(state.shortcuts.length - 2), [
      HomeShortcut.race,
      HomeShortcut.stars,
    ]);
  });

  test(
    'melhorar o jogo sem treino: a Jornada no cartão, sem texto de venda',
    () async {
      final state = await load(GoalPreference.improve);

      expect(state.hero, HomeHero.journey);
      expect(state.endgame!.lessonId, 'rook.lucena');
      expect(state.endgame!.recommended, isTrue);
      expect(state.shortcuts.first, HomeShortcut.pillars);
    },
  );

  test('melhorar o jogo: a aula de final começada segue calculada', () async {
    endgames = FakeEndgameProgressRepository(
      const EndgameProgress(
        lessons: {
          'rook.philidor': EndgameLessonProgress(stars: {'e01': 0}),
        },
      ),
    );
    final state = await load(GoalPreference.improve);

    expect(state.hero, HomeHero.journey);
    expect(state.endgame!.lessonId, 'rook.philidor');
    expect(state.endgame!.progress, greaterThan(0));
  });

  test('treinar finais: o final da faixa e a posição por cumprir', () async {
    final state = await load(GoalPreference.train);

    expect(state.hero, HomeHero.train);
    final train = state.trainGoal!;
    expect(train.suggestion.subcategory.key, 'queen');
    expect((train.suggestion.done, train.suggestion.total), (0, 1));
    expect(train.fen, samplePositions.first.fen);
    expect(state.shortcuts.first, HomeShortcut.train);
  });

  test('aprender a jogar: o cartão do objetivo é a próxima aula da Escola '
      '(S6 do T85)', () async {
    final state = await load(GoalPreference.learn, rating: 800);

    expect(state.hero, HomeHero.school);
    expect(state.school!.lessonTitle, 'The rook');
    expect(state.school!.done, 0);
  });

  test(
    'aprender a jogar: outros objetivos não ganham o cartão da Escola',
    () async {
      for (final goal in [
        GoalPreference.train,
        GoalPreference.explore,
        GoalPreference.challenge,
      ]) {
        expect(
          (await load(goal, rating: 800)).hero,
          isNot(HomeHero.school),
          reason: '$goal',
        );
      }
    },
  );

  test(
    'aprender a jogar com a Escola concluída: a Jornada no cartão',
    () async {
      await playJourney();
      final state = await load(
        GoalPreference.learn,
        rating: 800,
        schoolProgress: FakeSchoolProgressRepository(
          SchoolProgress(
            completed: {
              for (final lesson in FakeLessonRepository.sample.lessons)
                lesson.id,
            },
          ),
        ),
      );

      expect(state.hero, HomeHero.journey);
      expect(state.shortcuts, [
        HomeShortcut.school,
        HomeShortcut.journey,
        HomeShortcut.race,
        HomeShortcut.stars,
      ]);
    },
  );

  test('aprender a jogar antes de vencer o Coco: os mesmos atalhos', () async {
    final state = await load(GoalPreference.learn, rating: 800);

    expect(state.shortcuts, [
      HomeShortcut.school,
      HomeShortcut.journey,
      HomeShortcut.race,
      HomeShortcut.stars,
    ]);
  });

  group('Pilares no lugar do Curso de finais (H-INI-06)', () {
    const empty = EndgameTrail(modules: []);

    test('a home nunca tem o Curso de finais, com ou sem aula', () async {
      for (final trail in [null, empty]) {
        final state = trail == null
            ? await load(null)
            : await load(null, trail: trail);

        expect(state.shortcuts, contains(HomeShortcut.pillars));
        expect(state.layout!.order, contains(HomePath.endgames));
        expect(state.layout!.order, contains(HomePath.forYou));
      }
    });

    test('"Explorar posições": o Tabuleiro livre abre a lista', () async {
      final state = await load(GoalPreference.explore);

      expect(state.hero, HomeHero.board);
      expect(state.shortcuts.take(2), [
        HomeShortcut.freeBoard,
        HomeShortcut.customPosition,
      ]);
    });
  });

  group('home do iniciante e dos finais (T83 B3, B4)', () {
    test('o rating de quem aprende a jogar espera 3 partidas', () async {
      final ratings = FakeRatingRepository();
      expect(
        (await load(GoalPreference.learn, ratings: ratings)).showsRating,
        isFalse,
      );

      for (var i = 0; i < 3; i++) {
        ratings.entries.add(
          RatingEntry(rating: PlayerRating.start(800 + i), at: now()),
        );
      }
      final state = await load(GoalPreference.learn, ratings: ratings);
      expect(state.ratedGames, 3);
      expect(state.showsRating, isTrue);
    });

    test('bônus de speedrun não conta como partida', () async {
      final ratings = FakeRatingRepository()
        ..entries.add(
          RatingEntry(
            rating: PlayerRating.start(900),
            at: now(),
            speedrunAttemptId: 1,
          ),
        );
      expect(
        (await load(GoalPreference.learn, ratings: ratings)).ratedGames,
        0,
      );
    });

    test(
      'os finais em destaque esperam a primeira vitória do iniciante',
      () async {
        expect((await load(GoalPreference.learn)).showsFeatured, isFalse);
        await playJourney();
        expect((await load(GoalPreference.learn)).showsFeatured, isTrue);
        expect((await load(GoalPreference.train)).showsFeatured, isTrue);
      },
    );

    test('placementDone: só com o teste de nível feito', () async {
      final placement = FakePlacementRepository();
      expect((await load(null, placement: placement)).placementDone, isFalse);
      expect((await load(null)).placementDone, isTrue);
    });
  });
}
