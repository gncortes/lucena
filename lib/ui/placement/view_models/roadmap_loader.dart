import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/placement/placement_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/placement.dart';
import '../../../domain/use_cases/placement_roadmap.dart';

/// Monta o roteiro do jogador (T52) a partir do resultado gravado e do
/// progresso real, para a escola, a trilha de finais e o resultado do teste.
class RoadmapLoader {
  const RoadmapLoader({
    required this.placement,
    required this.school,
    required this.schoolProgress,
    required this.endgames,
    required this.endgameProgress,
  });

  final PlacementRepository placement;
  final LessonRepository school;
  final SchoolProgressRepository schoolProgress;
  final EndgameLessonRepository endgames;
  final EndgameProgressRepository endgameProgress;

  /// O roteiro do resultado gravado. Nulo sem teste feito.
  Future<PlacementRoadmap?> load() async {
    final result = await placement.result();
    if (result == null) return null;
    return build(result);
  }

  /// O roteiro de [result].
  Future<PlacementRoadmap> build(PlacementResult result) async {
    final skills = await placement.skills();
    final course = await school.course();
    final trail = await endgames.trail();
    final schoolDone = await schoolProgress.load();
    final endgamesDone = await endgameProgress.load();
    return PlacementRoadmap.build(
      result: result,
      skills: skills,
      schoolLessons: [for (final lesson in course.lessons) lesson.id],
      endgameLessons: [for (final lesson in trail.lessons) lesson.id],
      completedSchool: schoolDone.completed,
      completedEndgames: {
        for (final entry in endgamesDone.lessons.entries)
          if (entry.value.lessonDone) entry.key,
      },
    );
  }
}
