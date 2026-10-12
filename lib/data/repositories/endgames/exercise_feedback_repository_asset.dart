import 'dart:convert';

import '../../../domain/models/exercise_error_feedback.dart';
import '../../../domain/models/explanation.dart';
import '../../services/asset_service.dart';
import 'exercise_feedback_repository.dart';

class AssetExerciseFeedbackRepository
    implements
        ExerciseFeedbackRepository,
        ExplanationRepository,
        ExerciseReviewRepository {
  AssetExerciseFeedbackRepository(this._assets);

  final AssetService _assets;
  final _positions = <String, List<Map<String, dynamic>>>{};
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
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(lessonId)) {
      return null;
    }
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

  @override
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
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(lessonId) ||
        ExerciseErrorFeedback.positionKey(fen) == null) {
      return null;
    }
    final rows = await (_lessons[lessonId] ??= _load(lessonId));
    ExplanationPayload? base;
    for (final position in _positions[lessonId] ?? <Map<String, dynamic>>[]) {
      if (position['kind'] != kind ||
          position['id'] != exerciseId ||
          position['turn'] != turn ||
          ExerciseErrorFeedback.positionKey(position['fen'] as String? ?? '') !=
              ExerciseErrorFeedback.positionKey(fen)) {
        continue;
      }
      final localized = position['explanations'] as Map? ?? {};
      final data = localized[language] ?? localized['en'];
      if (data is Map) {
        try {
          base = ExplanationPayload.fromJson(Map<String, dynamic>.from(data));
        } catch (_) {
          /* Keep playing with legacy text. */
        }
      }
      break;
    }
    ExplanationPayload? rejected;
    if (state == ExplanationState.incorrect &&
        playedUci != null &&
        base == null) {
      for (final row in rows) {
        if (row.matches(
          lessonId: lessonId,
          exerciseId: exerciseId,
          kind: kind,
          turn: turn,
          fen: fen,
          uci: playedUci,
        )) {
          rejected = row.payload(language);
          break;
        }
      }
    }
    if (base == null && rejected == null) {
      return null;
    }
    return (base ?? ExplanationPayload.context(const [])).forState(
      state,
      playedUci: playedUci,
      rejected: rejected,
    );
  }

  @override
  Future<ExplanationPayload?> findExerciseReview({
    required String lessonId,
    required String exerciseId,
    required String language,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(lessonId)) return null;
    await (_lessons[lessonId] ??= _load(lessonId));
    final positions = [
      for (final p in _positions[lessonId] ?? <Map<String, dynamic>>[])
        if (p['kind'] == 'exercise' && p['id'] == exerciseId) p,
    ]..sort((a, b) => (a['turn'] as int).compareTo(b['turn'] as int));
    final blocks = <ExplanationBlock>[];
    final namespaces = <String>{};
    for (final position in positions) {
      final localized = position['explanations'] as Map? ?? {};
      final data = localized[language] ?? localized['en'];
      if (data is! Map) return null;
      try {
        final payload = ExplanationPayload.fromJson(
          Map<String, dynamic>.from(data),
        ).forState(ExplanationState.review);
        // Every decision keeps its own origin and ids, even if local author ids repeat.
        final namespace = payload.positionId.isEmpty
            ? 'exercise/$exerciseId.${position['turn']}'
            : payload.positionId;
        if (!namespaces.add(namespace)) return null;
        for (final block in payload.explanations) {
          blocks.add(
            ExplanationBlock(
              id: '$namespace:${block.id}',
              kind: block.kind,
              title: block.title,
              texts: block.texts,
              variations: [
                for (final variation in block.variations)
                  ExplanationVariation(
                    id: '$namespace:${variation.id}',
                    contextId:
                        '$namespace:${variation.contextId ?? payload.positionId}',
                    parentId: variation.parentId == null
                        ? null
                        : '$namespace:${variation.parentId}',
                    parentPly: variation.parentPly,
                    label: variation.label,
                    outcome: variation.outcome,
                    outcomeText: variation.outcomeText,
                    texts: variation.texts,
                    originFen: variation.originFen,
                    movesUci: variation.movesUci,
                    movesSan: variation.movesSan,
                    validated: variation.validated,
                    explanationByPly: variation.explanationByPly,
                  ),
              ],
            ),
          );
        }
      } catch (_) {
        // An incomplete review must not replace the complete legacy solution.
        return null;
      }
    }
    return blocks.isEmpty
        ? null
        : ExplanationPayload(
            positionId: '$lessonId:exercise:$exerciseId',
            state: ExplanationState.review,
            explanations: blocks,
          );
  }

  Future<List<ExerciseErrorFeedback>> _load(String lessonId) async {
    try {
      final json = jsonDecode(
        await _assets.loadString(assetPath(lessonId)),
      ) as Map<String, dynamic>;
      if (json['lesson'] != lessonId) return const [];
      _positions[lessonId] = [
        for (final p in json['positions'] as List? ?? [])
          Map<String, dynamic>.from(p as Map),
      ];
      return [
        for (final row
            in (json['rows'] as List? ?? []).cast<Map<String, dynamic>>())
          if (row['kind'] == 'exercise' || row['kind'] == 'move')
            ExerciseErrorFeedback.fromJson(lessonId, row),
      ];
    } catch (_) {
      // Most lessons have no feedback asset; malformed data must not block play.
      return const [];
    }
  }
}
