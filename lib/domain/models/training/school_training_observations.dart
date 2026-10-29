import '../star_challenge.dart';

/// Dated source records. Callers must use fulfilled attempts, never visits/bests.
final class SchoolBotWin {
  const SchoolBotWin({
    required this.positionId,
    required this.rung,
    required this.at,
  });
  final String positionId, rung;
  final DateTime at;
}

final class SchoolSpeedrunFinish {
  const SchoolSpeedrunFinish({required this.id, required this.at});
  final String id;
  final DateTime at;
}

final class SchoolTrainingObservations {
  SchoolTrainingObservations({
    Iterable<StarChallengeRun> starRuns = const [],
    Iterable<SchoolBotWin> botWins = const [],
    Iterable<SchoolSpeedrunFinish> speedruns = const [],
  }) : starRuns = List.unmodifiable(starRuns),
       botWins = List.unmodifiable(botWins),
       speedruns = List.unmodifiable(speedruns);
  final List<StarChallengeRun> starRuns;
  final List<SchoolBotWin> botWins;
  final List<SchoolSpeedrunFinish> speedruns;
}
