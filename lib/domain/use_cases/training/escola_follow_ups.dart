import '../../models/star_challenge.dart';
import '../../models/training/day_goals.dart';
import '../../models/training/school_training_progress.dart';
import '../../models/training/training_content.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_course_config.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'training_date.dart';

final class EscolaFollowUps implements TrainingFollowUps {
  const EscolaFollowUps();
  static const botPositions = {
    'mates.twoRooks': 'basic.twoRooks.0001',
    'mates.queen': 'basic.queen.0001',
  };

  @override
  TrainingState lessonCompleted(
    TrainingState state,
    TrainingLesson lesson,
    String date,
  ) {
    if (lesson.groupId != 'firstMates' ||
        state.school.speedrunCompletedOn != null ||
        state.completedLessons.containsKey(lesson.id)) {
      return state;
    }
    final previous = state.school;
    return state.copyWith(
      school: SchoolTrainingProgress(
        pieceLevels: previous.pieceLevels,
        pieceAdvancedOn: previous.pieceAdvancedOn,
        botsCompletedOn: previous.botsCompletedOn,
        speedrunCompletedOn: previous.speedrunCompletedOn,
        speedrunOriginLesson: lesson.id,
      ),
    );
  }

  @override
  List<TrainingGoal> build(
    TrainingState state,
    TrainingResources resources,
    Now now,
  ) {
    final date = trainingDate(now());
    final plan = state.day?.date == date ? state.day!.plan : state.plan;
    if (!plan.studiesOn(now())) return [];
    final visible = resources.lessons.where((l) => l.visible).toList();
    final completed = visible
        .where((l) => state.completedLessons.containsKey(l.id))
        .map((l) => l.id)
        .toSet();
    final progress = state.school;
    final mates = visible.where((l) => l.groupId == 'firstMates').toList();
    return [
      for (final entry in botPositions.entries)
        if (completed.contains(entry.key) &&
            !progress.botsCompletedOn.containsKey(entry.key))
          TrainingGoal(
            kind: GoalKind.bot,
            ref: entry.key,
            itemId: entry.value,
            items: const {'rung': '1000'},
          ),
      if (mates.isNotEmpty &&
          mates.every((l) => completed.contains(l.id)) &&
          progress.speedrunCompletedOn == null)
        TrainingGoal(
          kind: GoalKind.speedrun,
          ref: 'firstMates',
          itemId: 'journey.mates',
          items: {
            'initialSeconds': '900',
            'incrementSeconds': '10',
            if (progress.speedrunOriginLesson != null)
              'lessonId': progress.speedrunOriginLesson!,
          },
        ),
      for (final piece in ChallengePiece.values)
        if (completed.contains('pieces.${piece.name}') &&
            (progress.pieceLevels[piece.name] ?? 0) < 3 &&
            progress.pieceAdvancedOn[piece.name] != date)
          TrainingGoal(
            kind: GoalKind.stars,
            ref: 'pieces.${piece.name}',
            itemId: ChallengeLevel
                .values[progress.pieceLevels[piece.name] ?? 0]
                .name,
            stars: (progress.pieceLevels[piece.name] ?? 0) + 1,
          ),
    ];
  }
}
