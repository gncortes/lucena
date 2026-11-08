/// An explicit local completion command, distinct from account/version records.
/// Reopening a result screen or importing old progress never creates one.
final class LearningUnitCompletion {
  const LearningUnitCompletion({
    required this.kind,
    required this.unitId,
    required this.at,
    this.testPassed = false,
  });
  final String kind, unitId;
  final DateTime at;
  final bool testPassed;
}
