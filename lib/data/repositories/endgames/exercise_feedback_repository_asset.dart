import 'dart:convert';

import '../../../domain/models/exercise_error_feedback.dart';
import '../../services/asset_service.dart';
import 'exercise_feedback_repository.dart';

class AssetExerciseFeedbackRepository implements ExerciseFeedbackRepository {
  AssetExerciseFeedbackRepository(this._assets);

  final AssetService _assets;
  final _lessons = <String, Future<List<ExerciseErrorFeedback>>>{};
  static String assetPath(String lessonId) =>
      'assets/lessons/feedback/$lessonId.json';

  @override
  Future<String?> find({
    required String lessonId,
    required String exerciseId,
    required String kind,
    required int turn,
    required String fen,
    required String uci,
    required String language,
  }) async {
    // Lesson ids are identifiers, never caller-controlled asset paths.
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(lessonId)) return null;
    final rows = await (_lessons[lessonId] ??= _load(lessonId));
    for (final row in rows) {
      if (row.matches(
        lessonId: lessonId,
        exerciseId: exerciseId,
        kind: kind,
        turn: turn,
        fen: fen,
        uci: uci,
      )) {
        return row.text(language);
      }
    }
    return null;
  }

  Future<List<ExerciseErrorFeedback>> _load(String lessonId) async {
    try {
      final json = jsonDecode(
        await _assets.loadString(assetPath(lessonId)),
      ) as Map<String, dynamic>;
      if (json['lesson'] != lessonId) return const [];
      return [
        for (final row in (json['rows'] as List).cast<Map<String, dynamic>>())
          if (row['kind'] == 'exercise' || row['kind'] == 'move')
            ExerciseErrorFeedback.fromJson(lessonId, row),
      ];
    } catch (_) {
      // Most lessons have no feedback asset; malformed data must not block play.
      return const [];
    }
  }
}
