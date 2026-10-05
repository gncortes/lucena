import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';

import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeRatingRepository rating;
  final now = FakeNow(DateTime(2026, 10, 5, 15));

  setUp(() {
    progress = FakeProgressRepository();
    rating = FakeRatingRepository();
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
      achievements: FakeAchievementsRepository(),
      speedruns: FakeSpeedrunRepository(progress),
      now: now,
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

  test('o painel do jogador: apelido, faixa e os números', () async {
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
    expect(home.state.stats.games, 2);
    expect(home.state.stats.wins, 1);
    expect(home.state.stats.streakDays, 1);
    expect(home.state.ratingChange, greaterThan(0));
    expect(home.state.achievementsTotal, greaterThan(0));
    expect(home.state.bestSpeedrun, isNull);
  });
}
