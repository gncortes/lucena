import '../../../domain/models/assessment_attempt.dart';
import '../../../domain/use_cases/assessment_relations.dart';

enum AssessmentTechnicalFailure {
  storage,
  replay,
  integrity,
  invalidCommand,
  invalidMove,
  opponentUnavailable,
  illegalOpponent,
  factsUnavailable,
}

/// Collection state has no score, grade, solution or private conceptual facts.
final class AssessmentState {
  AssessmentState({
    this.snapshot,
    this.busy = false,
    this.technicalFailure,
    this.conceptualResult,
  }) : assert(
         conceptualResult == null || snapshot?.phase == AssessmentPhase.closed,
       );

  final AssessmentAttempt? snapshot;
  final bool busy;
  final AssessmentTechnicalFailure? technicalFailure;
  final AssessmentConceptResult? conceptualResult;
}
