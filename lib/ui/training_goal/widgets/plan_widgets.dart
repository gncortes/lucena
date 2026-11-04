import 'package:flutter/material.dart';

import '../../../domain/models/training/goal/study_plan.dart';
import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_card.dart';
import 'goal_format.dart';

/// Uma semana do plano: número, datas, capítulos (ou "só revisão").
class WeekCard extends StatelessWidget {
  const WeekCard({
    required this.view,
    required this.week,
    required this.index,
    this.current = false,
    this.onTap,
    super.key,
  });

  final GoalView view;
  final PlanWeek week;
  final int index;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final chapters = [
      for (final id in week.chapterIds)
        if (view.chapter(id) != null) view.chapter(id)!,
    ];
    final items = chapters.fold(0, (a, c) => a + c.itemCount);
    return LucenaCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.treinoWeekHeader(index + 1),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (week.review)
                Text(t.treinoWeekReviewTag, style: theme.textTheme.labelMedium),
            ],
          ),
          Text(
            t.treinoWeekRange(
              civilShort(context, week.start),
              civilShort(context, week.end),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (chapters.isEmpty)
            Text(t.treinoWeekReviewOnly)
          else ...[
            for (final c in chapters)
              Text(t.treinoChapterLine(view.chapterNumber(c.id), c.title)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.treinoWeekLessonsAndTest(items - chapters.length),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
