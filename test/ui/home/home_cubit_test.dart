import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/ui/placement/view_models/roadmap_loader.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../domain/placement_fixtures.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeRatingRepository rating;
  late FakeEndgameProgressRepository endgames;
  final now = FakeNow(DateTime(2026, 10, 5, 15));

  setUp(() {
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
    endgames = FakeEndgameProgressRepository();
  });

  HomeCubit cubit({
    Onboarding onboarding = const Onboarding(done: true),
    FakeHomeLayoutRepository? layout,
    FakePlacementRepository? placement,
    FakeFeaturedRepository? featured,
    FakeFeaturedProgressRepository? featuredProgress,
  }) {
    final cubit = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: progress,
      onboarding: FakeOnboardingRepository(onboarding),
      characters: FakeCharacterRepository(),
      rating: rating,
      lessons: FakeLessonRepository(),
      school: FakeSchoolProgressRepository(),
      profile: FakeProfileRepository(
        const UserProfile(nickname: 'Ana', rating: 1150),
      ),
      endgameLessons: FakeEndgameLessonRepository(),
      endgameProgress: endgames,
      homeLayout: layout,
      placement: placement,
      featured: featured,
      featuredProgress: featuredProgress,
      now: featured == null ? null : now,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  FakeHomeLayoutRepository priority(HomePath first) => FakeHomeLayoutRepository(
    layout: HomeLayout(
      order: [
        first,
        for (final path in HomePath.values)
          if (path != first) path,
      ],
      visible: {
        if (first != HomePath.forYou) HomePath.endgames,
        HomePath.journey,
        if (first == HomePath.forYou) HomePath.forYou,
      },
      custom: true,
    ),
  );
  FakePlacementRepository placed() => FakePlacementRepository(
    skills: smallSkills(),
    saveResultValue: resultWith({'rook.lucena': gap, 'rook.philidor': gap}),
  );

  test('E1.17: a home destaca o primeiro final em destaque', () async {
    final home = cubit(
      featured: FakeFeaturedRepository(sampleFeaturedCatalog()),
      featuredProgress: FakeFeaturedProgressRepository(),
    );
    await home.load();
    expect(home.state.featured?.id, 'b');
  });

  test('E1.17: sem finais em destaque, a home não mostra a seção', () async {
    final home = cubit(
      featured: FakeFeaturedRepository(),
      featuredProgress: FakeFeaturedProgressRepository(),
    );
    await home.load();
    expect(home.state.featured, isNull);
    final plain = cubit();
    await plain.load();
    expect(plain.state.featured, isNull);
  });

  test('C9: finais prioritários mostram a mesma próxima aula do roteiro, não iniciada', () async {
    final placement = placed();
    final home = cubit(
      layout: priority(HomePath.endgames),
      placement: placement,
    );
    await home.load();
    final roadmap = await RoadmapLoader(
      placement: placement,
      school: FakeLessonRepository(),
      schoolProgress: FakeSchoolProgressRepository(),
      endgames: FakeEndgameLessonRepository(),
      endgameProgress: endgames,
    ).load();
    final expected = roadmap!.steps.firstWhere((step) => !step.school);
    expect(home.state.hero, HomeHero.endgame);
    expect(home.state.endgame!.lessonId, expected.lessonId);
    expect(home.state.endgame!.lessonId, 'rook.lucena');
    expect(home.state.endgame!.recommended, isTrue);
    expect(home.state.endgame!.lessonOpen, isFalse);
    expect(home.state.endgame!.openExerciseId, isNull);
    expect(endgames.saved.lessons, isEmpty);
  });

  test('C9: conclusão avança a recomendação usando progresso atual', () async {
    final home = cubit(
      layout: priority(HomePath.endgames),
      placement: placed(),
    );
    await home.load();
    expect(home.state.endgame!.lessonId, 'rook.lucena');
    await endgames.save(
      const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1, 'e02': 2, 'e03': 3},
          ),
        },
      ),
    );
    await home.load();
    expect(home.state.endgame!.lessonId, 'rook.philidor');
    expect(home.state.endgame!.recommended, isTrue);
  });

  test(
    'C9: prioridade Jornada preserva destaque da Jornada mesmo com teste',
    () async {
      final home = cubit(
        layout: priority(HomePath.journey),
        placement: placed(),
      );
      await home.load();
      expect(home.state.endgame, isNull);
      expect(home.state.hero, HomeHero.journey);
    },
  );

  test('C9: sem teste mantém fallback Jornada', () async {
    final home = cubit(
      layout: priority(HomePath.endgames),
      placement: FakePlacementRepository(),
    );
    await home.load();
    expect(home.state.endgame, isNull);
    expect(home.state.hero, HomeHero.journey);
  });

  test('C9: Para você também abre a recomendação do roteiro', () async {
    final home = cubit(layout: priority(HomePath.forYou), placement: placed());
    await home.load();
    expect(home.state.endgame!.lessonId, 'rook.lucena');
    expect(home.state.hero, HomeHero.endgame);
  });

  test(
    'C9: aula em andamento continua no ponto salvo antes da recomendação',
    () async {
      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          ongoing: LessonCheckpoint(lessonId: 'rook.philidor', step: 0),
        ),
      );
      final home = cubit(
        layout: priority(HomePath.endgames),
        placement: placed(),
      );
      await home.load();
      expect(home.state.endgame!.lessonId, 'rook.philidor');
      expect(home.state.endgame!.recommended, isFalse);
      expect(home.state.endgame!.lessonOpen, isTrue);
    },
  );

  test('onde estou, contra quem e o próximo desafio', () async {
    final home = cubit();
    await home.load();

    expect(home.state.current!.rung.id, '1000');
    expect(home.state.next, sampleLadder.first.challenges.first);
    expect(home.state.character!.name, 'Coco');
    expect(home.state.rating, 1150);
    expect(home.state.tourPending, isFalse);
  });

  test('primeira abertura: o tour está pendente', () async {
    final home = cubit(onboarding: const Onboarding());
    await home.load();
    expect(home.state.tourPending, isTrue);
  });

  test('com o degrau escolhido no tour, a Jornada começa nele', () async {
    final home = cubit(
      onboarding: const Onboarding(done: true, startRung: '1200'),
    );
    await home.load();
    expect(home.state.current!.rung.id, '1200');
  });

  test('o painel do jogador: apelido, faixa e a variação do rating', () async {
    final game = Attempt(
      positionId: 'basic.queen.0001',
      playedAt: now(),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      opponentLevel: 1000,
    );
    await progress.addAttempt(game);
    await progress.addAttempt(game.copyWith(outcome: AttemptOutcome.loss));
    await rating.rate(game, userSide: Side.white, drawGoal: false);
    await rating.rate(game, userSide: Side.white, drawGoal: false);

    final home = cubit();
    await home.load();

    expect(home.state.nickname, 'Ana');
    expect(home.state.level, RatingLevel.of(1150));
    expect(home.state.ratingChange, greaterThan(0));
  });

  test('lição da escola começada aparece para qualquer perfil', () async {
    final home = HomeCubit(
      journey: FakeJourneyRepository(),
      progress: progress,
      onboarding: FakeOnboardingRepository(const Onboarding(done: true)),
      characters: FakeCharacterRepository(),
      rating: rating,
      lessons: FakeLessonRepository(),
      school: FakeSchoolProgressRepository(
        const SchoolProgress(
          ongoing: LessonCheckpoint(lessonId: 'pieces.rook', step: 2),
        ),
      ),
      profile: FakeProfileRepository(
        const UserProfile(nickname: 'Ana', rating: 1150),
      ),
      endgameLessons: FakeEndgameLessonRepository(),
      endgameProgress: endgames,
    );
    addTearDown(home.close);
    await home.load();
    expect(home.state.school?.ongoingLessonId, 'pieces.rook');
  });

  group('aula de final em andamento', () {
    test('sem aula começada, o cartão não aparece', () async {
      final home = cubit();
      await home.load();
      expect(home.state.endgame, isNull);
    });

    test('o exercício aberto, com a posição dele na lista', () async {
      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          lessons: {
            'rook.lucena': EndgameLessonProgress(
              lessonDone: true,
              stars: {'e01': 1},
              exercise: ExerciseCheckpoint(exerciseId: 'e02'),
            ),
          },
        ),
      );
      final home = cubit();
      await home.load();

      final endgame = home.state.endgame!;
      expect(endgame.lessonId, 'rook.lucena');
      expect(endgame.title, 'The Lucena position');
      expect(endgame.openExerciseId, 'e02');
      expect(endgame.exerciseNumber, 2);
      expect(endgame.exerciseCount, 3);
      expect(endgame.lessonOpen, isFalse);
      expect(endgame.score, 1);
      expect(endgame.maxScore, 6);
    });

    test('a lição aberta, sem o passo: fechar reabre no início', () async {
      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          ongoing: LessonCheckpoint(lessonId: 'rook.lucena', step: 1),
        ),
      );
      final home = cubit();
      await home.load();

      final endgame = home.state.endgame!;
      expect(endgame.lessonOpen, isTrue);
      expect(endgame.partNumber, isNull);
      expect(endgame.openExerciseId, isNull);
    });

    test('a lição interrompida (saiu no meio) também continua', () async {
      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          ongoing: LessonCheckpoint(
            lessonId: 'rook.lucena',
            step: 1,
            open: false,
          ),
        ),
      );
      final home = cubit();
      await home.load();

      final endgame = home.state.endgame!;
      expect(endgame.lessonOpen, isTrue);
    });

    test(
      'teste começado e nada aberto: o próximo exercício por resolver',
      () async {
        endgames = FakeEndgameProgressRepository(
          const EndgameProgress(
            lessons: {
              'rook.lucena': EndgameLessonProgress(
                lessonDone: true,
                stars: {'e01': 1, 'e02': 1},
              ),
            },
          ),
        );
        final home = cubit();
        await home.load();

        final endgame = home.state.endgame!;
        expect(endgame.lessonId, 'rook.lucena');
        // A miniatura dele vai no cartão e voa até o tabuleiro.
        expect(endgame.openExerciseId, 'e03');
        expect(endgame.exerciseNumber, 3);
        expect(endgame.exerciseFen, isNotNull);
        expect(endgame.lessonOpen, isFalse);
        expect(endgame.score, 2);
      },
    );

    test('lição feita e teste por começar: sem exercício no cartão', () async {
      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          lessons: {'rook.lucena': EndgameLessonProgress(lessonDone: true)},
        ),
      );
      final home = cubit();
      await home.load();

      final endgame = home.state.endgame!;
      expect(endgame.openExerciseId, isNull);
      expect(endgame.exerciseFen, isNull);
    });

    test('aula aprovada não volta para a tela inicial', () async {
      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          lessons: {
            'rook.lucena': EndgameLessonProgress(
              lessonDone: true,
              stars: {'e01': 1, 'e02': 2, 'e03': 3},
            ),
          },
        ),
      );
      final home = cubit();
      await home.load();
      expect(home.state.endgame, isNull);
    });
  });
}
