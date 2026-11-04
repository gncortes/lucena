import 'package:flutter/material.dart';

import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_card.dart';
import 'goal_format.dart';
import 'goal_page.dart';

/// Detalhe de uma semana (H-TRE-13): capítulos com lições feitas e o teste.
class TrainingWeekScreen extends StatelessWidget {
  const TrainingWeekScreen({
    required this.week,
    required this.onBack,
    required this.onChapter,
    super.key,
  });

  /// Índice da semana, a partir de zero.
  final int week;
  final VoidCallback onBack;
  final void Function(String chapterId) onChapter;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return GoalPage(
      screenKey: TrainingGoalKeys.weekScreen,
      title: t.treinoWeekHeader(week + 1),
      onBack: onBack,
      builder: (context, view) {
        final weeks = view.plan?.weeks ?? const [];
        if (week < 0 || week >= weeks.length) return const [];
        final w = weeks[week];
        final theme = Theme.of(context);
        return [
          Text(
            t.treinoWeekRange(
              civilShort(context, w.start),
              civilShort(context, w.end),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (w.chapterIds.isEmpty) Text(t.treinoWeekReviewOnly),
          for (final id in w.chapterIds)
            if (view.chapter(id) case final c?)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: LucenaCard(
                  onTap: () => onChapter(c.id),
                  child: Column(
                    key: TrainingGoalKeys.weekChapter(c.id),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.treinoChapterLine(view.chapterNumber(c.id), c.title),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        t.treinoLessonsDone(
                          view.progress(c).lessonsDone,
                          c.lessonIds.length,
                        ),
                      ),
                      if (c.testId != null) Text(t.treinoChapterTest),
                    ],
                  ),
                ),
              ),
        ];
      },
    );
  }
}
