import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/theme_cycle.dart';
import '../../../domain/models/training/training_course.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/course/training_badge.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';
import '../../endgames/widgets/stars_row.dart';

class TrainingThemeScreen extends StatelessWidget {
  const TrainingThemeScreen({
    required this.lessonId,
    required this.onBack,
    this.embedded = false,
    super.key,
  });
  final String lessonId;
  final VoidCallback onBack;
  final bool embedded;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<CourseGuideCubit, CourseGuideState>(
    builder: (context, state) {
      final t = context.l10n;
      final cycle = state.training?.cycles[lessonId];
      final lesson = state.resources?.lessons
          .where((l) => l.id == lessonId)
          .firstOrNull;
      final days = cycle?.cycleDays ?? const <ThemeDay>[];
      final body = cycle == null || lesson == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _card(context, [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(child: Text(t.trainingCycleScore)),
                      Text(
                        t.trainingPercent(cycle.score),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: cycle.score >= 70
                                  ? AppColors.of(context).success
                                  : cycle.score >= 30
                                  ? AppColors.goldInk
                                  : Theme.of(context).colorScheme.error,
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
                          primary: Theme.of(context).colorScheme.primary,
                          grid: Theme.of(context).colorScheme.outlineVariant,
                          success: AppColors.of(context).success,
                          error: Theme.of(context).colorScheme.error,
                          label:
                              Theme.of(context).textTheme.labelSmall ??
                              const TextStyle(),
                          threshold: t.trainingPercent(70),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    t.trainingChartLegend,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ]),
                const SizedBox(height: 12),
                _card(context, [
                  Text(
                    t.trainingByExercise,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Column(
                            spacing: 6,
                            children: [
                              if (i < days.length)
                                Semantics(
                                  label:
                                      '${i + 1}: ${TrainingBadge.difficultyLabel(context, days[i].stars)}, ${days[i].hint
                                          ? t.trainingWithHint
                                          : days[i].earned
                                          ? t.raceFeedbackCorrect
                                          : t.raceFeedbackWrong}',
                                  excludeSemantics: true,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        days[i].earned
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: StarsRow.colorFor(days[i].stars),
                                        size: 30,
                                      ),
                                      Positioned(
                                        right: -3,
                                        bottom: -3,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: days[i].earned
                                                ? AppColors.of(context).success
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            days[i].hint
                                                ? Icons.lightbulb_outline
                                                : days[i].earned
                                                ? Icons.check
                                                : Icons.close,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onError,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Icon(
                                  Icons.star_border,
                                  size: 30,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              Text(
                                '${i + 1}',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      for (var i = 1; i <= 3; i++)
                        Padding(
                          padding: EdgeInsets.zero,
                          child: TrainingBadge.difficulty(context, i),
                        ),
                    ],
                  ),
                ]),
                if (cycle.phase == ThemePhase.reinforce) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppShape.large),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        spacing: 12,
                        children: [
                          const Icon(Icons.replay),
                          Expanded(child: Text(t.trainingThemeReinforceInfo)),
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

  static Widget _card(BuildContext context, List<Widget> children) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppShape.large),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: children,
      ),
    ),
  );
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
    final left = 32.0, right = size.width - 10, bottom = size.height - 24;
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
        Paint()..color = success,
      );
    }
    text(threshold, Offset(right, y(70) - 10), end: true, color: success);
    var sum = 0;
    Offset? previous;
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
      canvas.drawCircle(
        point,
        4.5,
        Paint()..color = day.earned ? success : error,
      );
      previous = point;
    }
    for (var i = 0; i < 7; i++) {
      text('${i + 1}', Offset(x(i), size.height - 8));
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
