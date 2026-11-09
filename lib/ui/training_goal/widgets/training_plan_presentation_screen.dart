import 'package:flutter/material.dart';

import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import 'goal_format.dart';
import 'goal_page.dart';
import 'plan_widgets.dart';

/// Apresentação do plano (H-TRE-10): semanas com datas e capítulos, ou a
/// ordem do curso quando o objetivo é só melhorar.
class TrainingPlanPresentationScreen extends StatelessWidget {
  const TrainingPlanPresentationScreen({
    required this.onBack,
    required this.onStart,
    required this.onAdjust,
    required this.onWeek,
    super.key,
  });
  final VoidCallback onBack, onStart, onAdjust;
  final void Function(int weekIndex) onWeek;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return GoalPage(
      centerTitle: false,
      screenKey: TrainingGoalKeys.presentationScreen,
      cascata: true,
      title: t.treinoPlanTitle,
      onBack: onBack,
      builder: (context, view) {
        if (!view.hasTournament) {
          final count = view.plan?.chapterIds.length ?? 0;
          return [
            Text(
              t.treinoPlanOrderTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(t.treinoPlanOrderBody(count)),
          ];
        }
        final plan = view.plan;
        if (plan == null) return const [];
        final weeks = plan.weeks;
        return [
          Text(
            t.treinoPlanInWeeks(weeks.length),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            t.treinoPlanRange(
              weeks.isEmpty ? '' : civilShort(context, weeks.first.start),
              civilShort(context, view.tournamentDate!),
              plan.chapterIds.length,
            ),
          ),
          Text(t.treinoPlanEachChapter),
          const SizedBox(height: AppSpacing.md),
          for (final (i, w) in weeks.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: WeekCard(
                key: TrainingGoalKeys.presentationWeek(i),
                view: view,
                week: w,
                index: i,
                onTap: () => onWeek(i),
              ),
            ),
          if (plan.deferredIds.isNotEmpty)
            Text(
              t.treinoPlanDeferred(plan.deferredIds.length),
              key: TrainingGoalKeys.presentationDeferred,
            ),
        ];
      },
      footer: (context, view) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BusyButton(
            buttonKey: TrainingGoalKeys.presentationStart,
            label: t.treinoPlanStart,
            onPressed: onStart,
          ),
          const SizedBox(height: AppSpacing.sm),
          BusyButton(
            buttonKey: TrainingGoalKeys.presentationAdjust,
            label: t.treinoPlanAdjust,
            style: BusyButtonStyle.text,
            onPressed: onAdjust,
          ),
        ],
      ),
    );
  }
}
