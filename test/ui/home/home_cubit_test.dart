import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
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

  HomeCubit cubit({Onboarding onboarding = const Onboarding(done: true)}) {
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
    );
    addTearDown(cubit.close);
    return cubit;
  }

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

    test('a lição aberta, no passo em que parou', () async {
      endgames = FakeEndgameProgressRepository(
        const EndgameProgress(
          ongoing: LessonCheckpoint(lessonId: 'rook.lucena', step: 1),
        ),
      );
      final home = cubit();
      await home.load();

      final endgame = home.state.endgame!;
      expect(endgame.lessonOpen, isTrue);
      expect(endgame.step, 2);
      expect(endgame.stepCount, 2);
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
      expect(endgame.step, 2);
    });

    test('nada aberto: a aula começada e ainda não aprovada', () async {
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
      expect(endgame.openExerciseId, isNull);
      expect(endgame.lessonOpen, isFalse);
      expect(endgame.score, 2);
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
