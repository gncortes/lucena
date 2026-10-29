import 'package:lucena/data/repositories/school/star_challenge_repository.dart';
import 'package:lucena/domain/models/star_challenge.dart';

class FakeStarChallengeRepository implements StarChallengeRepository {
  FakeStarChallengeRepository([this.saved = const StarChallengeProgress()]);

  StarChallengeProgress saved;
  OpenStarChallenge? opened;
  final runs = <StarChallengeRun>[];

  @override
  Future<StarChallengeProgress> load() async => saved;

  @override
  Future<void> save(StarChallengeProgress progress) async {
    final best = {...saved.best};
    for (final entry in progress.best.entries) {
      if (entry.value > (best[entry.key] ?? 0)) best[entry.key] = entry.value;
    }
    saved = StarChallengeProgress(best: best);
  }

  @override
  Future<void> addRun({
    required ChallengePiece piece,
    required ChallengeLevel level,
    required int points,
    required DateTime at,
  }) async {
    await save(
      StarChallengeProgress(
        best: {StarChallengeProgress.keyOf(piece, level): points},
      ),
    );
    runs.add(
      StarChallengeRun(piece: piece, level: level, points: points, at: at),
    );
  }

  @override
  Future<List<StarChallengeRun>> runsSince(DateTime since) async =>
      List.unmodifiable(runs.where((r) => !r.at.isBefore(since)));

  @override
  Future<OpenStarChallenge?> open() async => opened;

  @override
  Future<void> setOpen(OpenStarChallenge? challenge) async =>
      opened = challenge;
}
