import '../../../domain/models/explanation.dart';

abstract class ExerciseFeedbackRepository {
  Future<String?> find({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String uci,
    required String language,
  });
}

/// Optional in older compositions and tests; the existing hint is the fallback.
class EmptyExerciseFeedbackRepository implements ExerciseFeedbackRepository {
  const EmptyExerciseFeedbackRepository();

  @override
  Future<String?> find({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String uci,
    required String language,
  }) async => null;
}

/// Rich lookup is optional so older repository implementations remain valid.
abstract interface class ExplanationRepository {
  Future<ExplanationPayload?> findPayload({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String language,
    required ExplanationState state,
    String? playedUci,
  });
}

extension ExplanationLookup on ExerciseFeedbackRepository {
  Future<ExplanationPayload?> findPayload({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String language,
    required ExplanationState state,
    String? playedUci,
  }) async {
    final repository = this;
    if (repository is ExplanationRepository) {
      final structured = repository as ExplanationRepository;
      return structured.findPayload(
        lessonId: lessonId,
        exerciseId: exerciseId,
        kind: kind,
        turn: turn,
        fen: fen,
        language: language,
        state: state,
        playedUci: playedUci,
      );
    }
    if (playedUci == null) return null;
    final text = await find(
      lessonId: lessonId,
      exerciseId: exerciseId,
      kind: kind,
      turn: turn,
      fen: fen,
      uci: playedUci,
      language: language,
    );
    return text == null ? null : ExplanationPayload.context([text]);
  }
}

/// All authored decisions in an exercise, independent of the user's path.
abstract interface class ExerciseReviewRepository {
  Future<ExplanationPayload?> findExerciseReview({
    required String lessonId,
    required String exerciseId,
    required String language,
  });
}

extension ExerciseReviewLookup on ExerciseFeedbackRepository {
  Future<ExplanationPayload?> findExerciseReview({
    required String lessonId,
    required String exerciseId,
    required String language,
  }) async {
    final repository = this;
    if (repository is ExerciseReviewRepository) {
      final reviews = repository as ExerciseReviewRepository;
      return reviews.findExerciseReview(
        lessonId: lessonId,
        exerciseId: exerciseId,
        language: language,
      );
    }
    // Preserve the complete original solution with legacy repositories.
    return null;
  }
}
