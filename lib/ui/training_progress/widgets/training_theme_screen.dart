import '../../core/theme/app_icon_size.dart';

import 'package:flutter/material.dart';
import 'package:dartchess/dartchess.dart' show Side;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/theme_cycle.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/course/training_badge.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/position_board.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';
import '../../course_guide/widgets/course_guide_copy.dart';

class TrainingThemeScreen extends StatelessWidget {
  const TrainingThemeScreen({
    required this.lessonId,
    required this.onBack,
    this.onExercise,
    this.embedded = false,
    super.key,
  });
  final String lessonId;
  final VoidCallback onBack;
  final ValueChanged<TrainingExercise>? onExercise;
  final bool embedded;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final t = context.l10n;
      final colors = Theme.of(context).colorScheme;
      final cycle = state.training?.cycles[lessonId];
      final lesson = state.resources?.lessons
          .where((l) => l.id == lessonId)
          .firstOrNull;
      final days = cycle?.cycleDays ?? const <ThemeDay>[];
      final bank =
          state.resources?.banks[lessonId] ?? const <TrainingExercise>[];
      final body = cycle == null || lesson == null
          ? const SizedBox.shrink()
          : ListView(
              key: TrainingKeys.themeScroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _card(context, [
                  Text(
                    trainingMasteryLessonTitle(context, lesson),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      height: 24 / 16,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.trainingCycleScore,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 20 / 14,
                              ),
                        ),
                      ),
                      Text(
                        t.trainingPercent(cycle.score),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 24,
                              height: 32 / 24,
                              fontWeight: FontWeight.w500,
                              color: cycle.score >= 70
                                  ? AppColors.trainingDayCorrect
                                  : cycle.score >= 30
                                  ? AppColors.trainingMasteryDeveloping
                                  : AppColors.trainingDayWrong,
                            ),
                      ),
                    ],
                  ),
                  Semantics(
                    label:
                        '${t.trainingCycleScore}: ${t.trainingPercent(cycle.score)}',
                    child: SizedBox(
                      key: TrainingKeys.themeChart,
                      height: 168,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _CyclePlot(
                          days: days,
                          primary: colors.primary,
                          grid: AppColors.trainingChartGrid,
                          success: AppColors.trainingDayCorrect,
                          error: AppColors.trainingDayWrong,
                          label:
                              (Theme.of(context).textTheme.labelSmall ??
                                      const TextStyle())
                                  .copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: colors.onSurfaceVariant,
                                  ),
                          threshold: t.trainingPercent(70),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    key: TrainingKeys.themeLegend,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      _legend(
                        context,
                        t.themeCanvasCorrect,
                        AppColors.trainingDayCorrect,
                      ),
                      _legend(
                        context,
                        t.themeCanvasWrong,
                        AppColors.trainingDayWrong,
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Text(
                    t.themeCanvasExercisesDone,
                    key: TrainingKeys.themeExercisesHeading,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      height: 24 / 16,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  [
                    for (final (index, day) in cycle.days.indexed)
                      _HistoryRow(
                        day: day,
                        index: index,
                        exercise: bank
                            .where((e) => e.id == day.exerciseId)
                            .firstOrNull,
                        onExercise: onExercise,
                      ),
                  ],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  spacing: 0,
                ),
                if (cycle.phase == ThemePhase.reinforce) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppShape.card),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        spacing: 12,
                        children: [
                          Icon(
                            Icons.replay,
                            size: AppIconSize.notice,
                            color: colors.primary,
                          ),
                          Expanded(
                            child: Text(
                              t.themeCanvasReinforceInfo(
                                cycle.reinforcement
                                    .where(
                                      (id) => !cycle.reinforceDays.any(
                                        (d) => d.exerciseId == id,
                                      ),
                                    )
                                    .length,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(height: 20 / 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
      if (embedded) {
        return KeyedSubtree(key: TrainingKeys.themeScreen, child: body);
      }
      return Scaffold(
        key: TrainingKeys.themeScreen,
        appBar: LucenaAppBar(
          title: Text(t.trainingThemeTitle),
          leading: BackButton(key: TrainingKeys.themeBack, onPressed: onBack),
        ),
        body: body,
      );
    },
  );

  static Widget _legend(BuildContext context, String label, Color color) => Row(
    spacing: 8,
    children: [
      SizedBox(
        width: 24,
        child: Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontSize: 12, height: 16 / 12, letterSpacing: 0),
      ),
    ],
  );

  static Widget _card(
    BuildContext context,
    List<Widget> children, {
    EdgeInsets padding = const EdgeInsets.all(16),
    double spacing = 12,
  }) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppShape.card),
    child: Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: children,
      ),
    ),
  );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.day,
    required this.index,
    required this.exercise,
    required this.onExercise,
  });
  final ThemeDay day;
  final int index;
  final TrainingExercise? exercise;
  final ValueChanged<TrainingExercise>? onExercise;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final color = day.earned
        ? AppColors.trainingDayCorrect
        : AppColors.trainingDayWrong;
    final result = day.earned ? t.themeCanvasCorrect : t.themeCanvasWrong;
    final elapsed = day.elapsedMs;
    final seconds = elapsed == null
        ? null
        : (elapsed.clamp(0, 1 << 53) ~/ 1000);
    final label = seconds == null
        ? result
        : t.themeCanvasResultTime(
            result,
            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
          );
    final source = exercise;
    final tap = source == null || onExercise == null
        ? null
        : () => onExercise!(source);
    return InkWell(
      key: TrainingKeys.themeExercise(index),
      onTap: tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            if (source != null)
              ExcludeSemantics(
                child: PositionBoard(
                  key: TrainingKeys.themeThumbnail(index),
                  fen: source.fen,
                  orientation: Side.white,
                  size: 56,
                  radius: AppShape.small,
                ),
              )
            else
              const SizedBox.square(dimension: 56),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    t.themeCanvasExercise(index + 1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      height: 24 / 16,
                      letterSpacing: 0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          TrainingBadge.difficultyIcon(
                            context,
                            day.stars,
                            size: 16,
                          ),
                          Flexible(
                            child: Text(
                              TrainingBadge.difficultyLabel(context, day.stars),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    height: 16 / 12,
                                    letterSpacing: 0,
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '·',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              day.earned ? Icons.check : Icons.close,
                              size: 10,
                              color: colors.onError,
                            ),
                          ),
                          Text(
                            label,
                            key: TrainingKeys.themeResult(index),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  letterSpacing: 0,
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 56,
              child: Center(
                child: day.earned
                    ? Icon(
                        Icons.chevron_right,
                        size: AppIconSize.standard,
                        color: colors.onSurfaceVariant,
                      )
                    : FilledButton(
                        key: TrainingKeys.themeRedo(index),
                        onPressed: tap,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                        child: Text(t.trainingPartRedo),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rating chart has a date axis and an adaptive rating range. This plot has
/// a fixed seven-exercise axis, 0–100 range and the course's 70% threshold.
class _CyclePlot extends CustomPainter {
  const _CyclePlot({
    required this.days,
    required this.primary,
    required this.grid,
    required this.success,
    required this.error,
    required this.label,
    required this.threshold,
  });
  final List<ThemeDay> days;
  final Color primary, grid, success, error;
  final TextStyle label;
  final String threshold;
  @override
  void paint(Canvas canvas, Size size) {
    final left = 36.0, right = size.width - 8, bottom = size.height - 24;
    double x(int i) => left + 8 + i * (right - left - 16) / 6;
    double y(num value) =>
        14 + (100 - value.clamp(0, 100)) * (bottom - 14) / 100;
    void text(String value, Offset position, {bool end = false, Color? color}) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: label.copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        position -
            Offset(end ? painter.width : painter.width / 2, painter.height / 2),
      );
    }

    for (final v in [0, 50, 100]) {
      canvas.drawLine(
        Offset(left, y(v)),
        Offset(right, y(v)),
        Paint()..color = grid,
      );
      text('$v', Offset(left - 6, y(v)), end: true);
    }
    for (double dx = left; dx < right; dx += 9) {
      canvas.drawLine(
        Offset(dx, y(70)),
        Offset((dx + 5).clamp(left, right), y(70)),
        Paint()
          ..color = success
          ..strokeWidth = 1.5,
      );
    }
    text(threshold, Offset(right, y(70) - 10), end: true, color: success);
    var sum = 0;
    Offset? previous;
    final points = <(Offset, bool)>[];
    for (var i = 0; i < days.length && i < 7; i++) {
      final day = days[i];
      if (day.earned) sum += day.stars;
      final point = Offset(x(i), y((sum * 100 / 15).round()));
      if (previous != null) {
        canvas.drawLine(
          previous,
          point,
          Paint()
            ..color = primary
            ..strokeWidth = 2.5,
        );
      }
      points.add((point, day.earned));
      previous = point;
    }
    for (final (point, earned) in points) {
      canvas.drawCircle(point, 4.5, Paint()..color = earned ? success : error);
    }
    for (var i = 0; i < 7; i++) {
      text('${i + 1}', Offset(x(i), size.height - 10));
    }
  }

  @override
  bool shouldRepaint(_CyclePlot oldDelegate) =>
      days != oldDelegate.days ||
      primary != oldDelegate.primary ||
      grid != oldDelegate.grid ||
      success != oldDelegate.success ||
      error != oldDelegate.error ||
      label != oldDelegate.label ||
      threshold != oldDelegate.threshold;
}
