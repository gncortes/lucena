import 'training_content.dart';

/// Snapshot of available private content. Missing files have no entry.
final class TrainingResources {
  TrainingResources({
    Iterable<TrainingLesson> lessons = const [],
    Map<String, List<TrainingExercise>> banks = const {},
    Map<String, List<OpeningTrecho>> openings = const {},
    Map<String, Map<String, String>> errorFeedback = const {},
    Iterable<String> offlineChapters = const [],
    this.hasUnpublishedContent = false,
  }) : lessons = List.unmodifiable(lessons),
       offlineChapters = Set.unmodifiable(offlineChapters),
       banks = Map.unmodifiable(
         banks.map(
           (k, v) => MapEntry(k, List<TrainingExercise>.unmodifiable(v)),
         ),
       ),
       errorFeedback = Map.unmodifiable(
         errorFeedback.map(
           (lesson, texts) =>
               MapEntry(lesson, Map<String, String>.unmodifiable(texts)),
         ),
       ),
       openings = Map.unmodifiable(
         openings.map(
           (k, v) => MapEntry(k, List<OpeningTrecho>.unmodifiable(v)),
         ),
       );
  final List<TrainingLesson> lessons;
  final Set<String> offlineChapters;
  final bool hasUnpublishedContent;
  final Map<String, List<TrainingExercise>> banks;
  final Map<String, List<OpeningTrecho>> openings;

  /// Localized private text keyed by exercise.studentTurn.wrongUci.
  final Map<String, Map<String, String>> errorFeedback;
}
