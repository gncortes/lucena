import '../domain/models/character.dart';
import '../ui/lesson_script/view_models/lesson_script_state.dart';
import '../ui/training_exercise/view_models/training_exercise_cubit.dart';
import '../ui/training_opening/view_models/training_opening_cubit.dart';

/// Optional, visual-only snapshot for a Home launch. Persistence and accepted
/// moves always come from the destination's own Cubit after it has loaded.
final class TrainingLaunch {
  const TrainingLaunch({
    required this.title,
    required this.teacher,
    this.lessonPreview,
    this.exercisePreview,
    this.openingPreview,
  });

  final String title;
  final Character teacher;
  final LessonScriptState? lessonPreview;
  final TrainingExerciseState? exercisePreview;
  final TrainingOpeningState? openingPreview;
}
