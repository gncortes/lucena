import '../../models/training/training_content.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import 'opening_parts.dart';

/// Existing repertoires are implicit choices for legacy installations.
bool needsOpeningProfile(
  TrainingState state,
  TrainingResources resources,
  TrainingLesson? lesson,
) =>
    state.course == TrainingCourse.pilares &&
    lesson?.kind == TrainingLessonKind.opening &&
    state.openingProfileStartPart.isEmpty &&
    state.openings.isEmpty &&
    !state.completedLessons.keys.any(
      (id) =>
          openingProfileForLesson(id) != null ||
          resources.lessons.any(
            (l) => l.id == id && l.kind == TrainingLessonKind.opening,
          ),
    );
