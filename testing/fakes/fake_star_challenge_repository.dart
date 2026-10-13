import 'package:lucena/data/repositories/school/star_challenge_repository.dart';
import 'package:lucena/domain/models/star_challenge.dart';

class FakeStarChallengeRepository implements StarChallengeRepository {
  FakeStarChallengeRepository([this.saved = const StarChallengeProgress()]);

  StarChallengeProgress saved;
  OpenStarChallenge? opened;

  @override
  Future<StarChallengeProgress> load() async => saved;

  @override
  Future<void> save(StarChallengeProgress progress) async => saved = progress;

  @override
  Future<OpenStarChallenge?> open() async => opened;

  @override
  Future<void> setOpen(OpenStarChallenge? challenge) async =>
      opened = challenge;
}
