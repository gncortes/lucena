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
