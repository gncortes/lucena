import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/goal/training_diagnostic.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_page.dart';

/// Questionário (H-TRE-09): uma área do curso por linha, escala de três níveis.
/// Cada resposta é gravada na hora.
class TrainingQuestionnaireScreen extends StatelessWidget {
  const TrainingQuestionnaireScreen({
    required this.onBack,
    required this.onBuilt,
    super.key,
  });
  final VoidCallback onBack;
  final VoidCallback onBuilt;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<TrainingGoalCubit>();
    String label(TopicLevel l) => switch (l) {
      TopicLevel.learning => t.treinoScaleLearning,
      TopicLevel.practicing => t.treinoScalePracticing,
      TopicLevel.mastered => t.treinoScaleMastered,
    };
    return GoalPage(
      screenKey: TrainingGoalKeys.questScreen,
      title: t.treinoQuestTitle,
      onBack: onBack,
      builder: (context, view) {
        final parts = <String, String>{};
        for (final c in view.chapters) {
          parts.putIfAbsent(c.partId, () => c.partTitle);
        }
        final answers = view.state.diagnostic?.topics ?? const {};
        return [
          if (answers.isNotEmpty && answers.length < parts.length)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                t.treinoQuestResumeTitle(answers.length, parts.length),
                key: TrainingGoalKeys.questResume,
              ),
            ),
          Text(t.treinoQuestIntro),
          const SizedBox(height: AppSpacing.md),
          for (final entry in parts.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: LucenaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<TopicLevel>(
                      showSelectedIcon: false,
                      emptySelectionAllowed: true,
                      segments: [
                        for (final l in TopicLevel.values)
                          ButtonSegment(
                            value: l,
                            label: Text(
                              label(l),
                              key: TrainingGoalKeys.questLevel(
                                entry.key,
                                l.name,
                              ),
                            ),
                          ),
                      ],
                      selected: {?answers[entry.key]},
                      onSelectionChanged: (set) {
                        if (set.isNotEmpty) {
                          cubit.answerTopic(entry.key, set.first);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
        ];
      },
      footer: (context, view) {
        final done =
            (view.state.diagnostic?.topics.length ?? 0) >=
            view.chapters.map((c) => c.partId).toSet().length;
        return BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
          builder: (context, state) => BusyButton(
            buttonKey: TrainingGoalKeys.questBuild,
            label: t.treinoQuestBuild,
            busy: state.saving,
            onPressed: done
                ? () async {
                    if (await cubit.finish()) onBuilt();
                  }
                : null,
          ),
        );
      },
    );
  }
}
