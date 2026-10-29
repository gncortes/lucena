import '../domain/models/character.dart';
import '../domain/models/journey.dart';
import '../domain/models/speedrun.dart';
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
    this.challenge,
    this.speedrun,
  });

  final String title;
  final Character teacher;
  final LessonScriptState? lessonPreview;
  final TrainingExerciseState? exercisePreview;
  final TrainingOpeningState? openingPreview;
  final Challenge? challenge;
  final Speedrun? speedrun;
}
