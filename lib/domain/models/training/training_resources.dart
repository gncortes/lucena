import 'training_content.dart';

/// Snapshot of available private content. Missing files have no entry.
final class TrainingResources {
  TrainingResources({
    Iterable<TrainingLesson> lessons = const [],
    Map<String, List<TrainingExercise>> banks = const {},
    Map<String, List<OpeningTrecho>> openings = const {},
  }) : lessons = List.unmodifiable(lessons),
       banks = Map.unmodifiable(
         banks.map(
           (k, v) => MapEntry(k, List<TrainingExercise>.unmodifiable(v)),
         ),
       ),
       openings = Map.unmodifiable(
         openings.map(
           (k, v) => MapEntry(k, List<OpeningTrecho>.unmodifiable(v)),
         ),
       );
  final List<TrainingLesson> lessons;
  final Map<String, List<TrainingExercise>> banks;
  final Map<String, List<OpeningTrecho>> openings;
}
