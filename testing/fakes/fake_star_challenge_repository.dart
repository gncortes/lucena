import 'package:lucena/data/repositories/school/star_challenge_repository.dart';
import 'package:lucena/domain/models/star_challenge.dart';

class FakeStarChallengeRepository implements StarChallengeRepository {
  FakeStarChallengeRepository([this.saved = const StarChallengeProgress()]);

  StarChallengeProgress saved;

  @override
  Future<StarChallengeProgress> load() async => saved;

  @override
  Future<void> save(StarChallengeProgress progress) async => saved = progress;
}
