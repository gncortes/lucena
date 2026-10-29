import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/star_challenge.dart';
import '../../../domain/models/training/training_course.dart';
import '../../core/keys/training_keys.dart';
import '../../core/keys/course_guide_keys.dart';
import '../../core/widgets/course/course_item_tile.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/widgets/animated_progress.dart';
import '../../core/widgets/course/piece_stars_row.dart';
import '../view_models/course_guide_cubit.dart';

class TrainingProgressTab extends StatelessWidget {
  const TrainingProgressTab({
    required this.onTheme,
    this.testScores = const {},
    this.testProgress = const {},
    this.onTest,
    this.onLevelTest,
    super.key,
  });
  final ValueChanged<String> onTheme;

  /// Percentages from operational test progress. Absence is never a zero score.
  final Map<String, int?> testScores;
  final Map<String, CourseTestProgress> testProgress;
  final ValueChanged<String>? onTest;
  final VoidCallback? onLevelTest;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final training = state.training, data = state.resources;
      if (training == null || data == null) return const SizedBox.shrink();
      final t = context.l10n;
      if (context.read<CourseGuideCubit>().config.progressKind ==
          TrainingProgressKind.modulesAndPieces) {
        final lessons = data.lessons.where((l) => l.visible).toList();
        final groups = {
          for (final lesson in lessons) lesson.groupId: lesson.group,
        };
        int completed(Iterable<String> ids) =>
            ids.where(training.completedLessons.containsKey).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _card(
              context,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.trainingProgressLessons,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      t.trainingCount(
                        lessons.length,
                        completed(lessons.map((l) => l.id)),
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                for (final group in groups.entries)
                  Builder(
                    builder: (context) {
                      final items = lessons
                          .where((l) => l.groupId == group.key)
                          .toList();
                      final done = completed(items.map((l) => l.id));
                      return Column(
                        key: TrainingKeys.moduleRow(group.key),
                        spacing: 6,
                        children: [
                          Row(
                            spacing: 12,
                            children: [
                              Expanded(
                                child: Text(
                                  group.value,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                t.trainingCount(items.length, done),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 6,
                            child: AnimatedProgress(
                              value: items.isEmpty ? 0 : done / items.length,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _card(
              context,
              children: [
                Text(
                  t.trainingProgressPieceStars,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final piece in [
                  ChallengePiece.rook,
                  ChallengePiece.bishop,
                  ChallengePiece.queen,
                  ChallengePiece.king,
                  ChallengePiece.knight,
                  ChallengePiece.pawn,
                ])
                  PieceStarsRow(
                    piece: piece,
                    completed: training.school.pieceLevels[piece.name] ?? 0,
                  ),
              ],
            ),
          ],
        );
      }
      final cycles = training.cycles;
      final tracks = training.openings;
      final firmMoves = tracks.values.fold(
        0,
        (n, track) => n + track.firmMoves,
      );
      final seenMoves = tracks.values.fold(
        0,
        (n, track) => n + track.seenMoves,
      );
      final tests = data.lessons
          .where((l) => l.kind == TrainingLessonKind.test)
          .toList();
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _card(
            context,
            children: [
              Text(
                t.trainingMasteryTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                t.trainingMasteryNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              for (final lesson in data.lessons.where(
                (l) => cycles.containsKey(l.id),
              )) ...[
                InkWell(
                  key: TrainingKeys.masteryRow(lesson.id),
                  onTap: () => onTheme(lesson.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      spacing: 6,
                      children: [
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: Text(
                                lesson.title,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              cycles[lesson.id]!.cycleDays.length < 7
                                  ? t.trainingCycleDays(
                                      cycles[lesson.id]!.cycleDays.length,
                                    )
                                  : t.trainingPercent(cycles[lesson.id]!.score),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 28),
                          child: SizedBox(
                            height: 14,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final cycle = cycles[lesson.id]!;
                                final incomplete = cycle.cycleDays.length < 7;
                                // Canvas mastery colors belong to this chart;
                                // medal stars and global progress roles retain their defaults.
                                final color = incomplete
                                    ? Theme.of(context)
                                          .colorScheme
                                          .outlineVariant
                                    : cycle.score >= 70
                                    ? AppColors.trainingDayCorrect
                                    : cycle.score >= 30
                                    ? AppColors.trainingMasteryDeveloping
                                    : Theme.of(context).colorScheme.error;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Theme(
                                      data: Theme.of(context).copyWith(
                                        progressIndicatorTheme:
                                            Theme.of(context)
                                                .progressIndicatorTheme
                                                .copyWith(color: color),
                                      ),
                                      child: AnimatedProgress(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        value: incomplete
                                            ? cycle.cycleDays.length / 7
                                            : (cycle.score / 100).clamp(0, 1),
                                      ),
                                    ),
                                    Positioned(
                                      left: .7 * constraints.maxWidth,
                                      top: 0,
                                      child: Container(
                                        width: 2,
                                        height: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (tracks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              context,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    const Icon(Icons.swap_vert),
                    Expanded(
                      child: Text(
                        t.trainingOpeningsTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      t.trainingOpeningCount(firmMoves, seenMoves),
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  t.trainingOpeningsFirm(firmMoves, seenMoves),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (tests.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card(
              context,
              children: [
                Text(
                  t.trainingTestsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final test in tests)
                  Builder(
                    builder: (context) {
                      final raw = testProgress[test.id];
                      final completed =
                          training.completedLessons.containsKey(test.id) ||
                          (raw != null &&
                              raw.total > 0 &&
                              raw.solved == raw.total);
                      final attempted =
                          (raw?.solved ?? 0) > 0 || testScores[test.id] != null;
                      final prerequisite = data.lessons
                          .where(
                            (l) =>
                                l.visible &&
                                l.kind != TrainingLessonKind.test &&
                                test.groupId.isNotEmpty &&
                                l.groupId == test.groupId &&
                                l.partId == test.partId &&
                                !training.completedLessons.containsKey(l.id),
                          )
                          .firstOrNull;
                      final locked =
                          !completed && !attempted && prerequisite != null;
                      final groups = data.lessons
                          .where((l) => l.visible && l.partId == test.partId)
                          .map((l) => l.groupId)
                          .toSet()
                          .toList();
                      final number = groups.indexOf(test.groupId) + 1;
                      return CourseItemTile(
                        key: CourseGuideKeys.chapterLesson(test.id),
                        state: completed
                            ? CourseItemState.approved
                            : locked
                            ? CourseItemState.locked
                            : attempted
                            ? CourseItemState.started
                            : CourseItemState.open,
                        title: t.trainingProgressChapterTitle(
                          number,
                          test.group.isEmpty ? test.title : test.group,
                        ),
                        summary: locked
                            ? t.trainingTestLocked(prerequisite.title)
                            : completed
                            ? t.trainingTestDoneBody
                            : test.summary.isNotEmpty
                            ? test.summary
                            : testScores[test.id] == null &&
                                  (raw?.solved ?? 0) == 0
                            ? t.trainingTestsMissing
                            : null,
                        medal: locked
                            ? null
                            : raw != null && raw.solved > 0
                            ? Text(
                                t.trainingCount(raw.maxScore, raw.score),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              )
                            : testScores[test.id] == null
                            ? const Icon(
                                Icons.chevron_right,
                                size: AppIconSize.button,
                              )
                            : Text(
                                t.trainingPercent(
                                  testScores[test.id]!.clamp(0, 100),
                                ),
                              ),
                        onTap: locked || onTest == null
                            ? null
                            : () => onTest!(test.id),
                      );
                    },
                  ),
                if (context.read<CourseGuideCubit>().config.hasLevelTest)
                  ListTile(
                    key: CourseGuideKeys.levelTest,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.quiz_outlined),
                    title: Text(t.placementTitle),
                    subtitle: Text(t.trainingLevelTestOptional),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onLevelTest,
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
  static Widget _card(BuildContext context, {required List<Widget> children}) =>
      Material(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShape.large),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: children,
          ),
        ),
      );
}
