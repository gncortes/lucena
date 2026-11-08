/// Operational training history, independent from dated source observations.
final class SchoolTrainingProgress {
  SchoolTrainingProgress({
    Map<String, int> pieceLevels = const {},
    Map<String, String> pieceAdvancedOn = const {},
    Map<String, String> botsCompletedOn = const {},
    this.speedrunCompletedOn,
    this.speedrunOriginLesson,
  }) : pieceLevels = Map.unmodifiable(pieceLevels),
       pieceAdvancedOn = Map.unmodifiable(pieceAdvancedOn),
       botsCompletedOn = Map.unmodifiable(botsCompletedOn);

  /// Number of completed levels, 0–3. Never inferred from a legacy best.
  final Map<String, int> pieceLevels;
  final Map<String, String> pieceAdvancedOn, botsCompletedOn;
  final String? speedrunCompletedOn, speedrunOriginLesson;
  Map<String, Object?> toJson() => {
    'pieceLevels': pieceLevels,
    'pieceAdvancedOn': pieceAdvancedOn,
    'botsCompletedOn': botsCompletedOn,
    'speedrunCompletedOn': speedrunCompletedOn,
    'speedrunOriginLesson': speedrunOriginLesson,
  };
  factory SchoolTrainingProgress.fromJson(Map<String, dynamic> json) =>
      SchoolTrainingProgress(
        pieceLevels: (json['pieceLevels'] as Map? ?? {}).cast<String, int>(),
        pieceAdvancedOn: (json['pieceAdvancedOn'] as Map? ?? {})
            .cast<String, String>(),
        botsCompletedOn: (json['botsCompletedOn'] as Map? ?? {})
            .cast<String, String>(),
        speedrunCompletedOn: json['speedrunCompletedOn'] as String?,
        speedrunOriginLesson: json['speedrunOriginLesson'] as String?,
      );
}
