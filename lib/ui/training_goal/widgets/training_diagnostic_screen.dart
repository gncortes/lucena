import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_page.dart';

/// "Como montar o plano" (H-TRE-07): teste de posições ou questionário.
class TrainingDiagnosticScreen extends StatelessWidget {
  const TrainingDiagnosticScreen({
    required this.onBack,
    required this.onTest,
    required this.onQuestionnaire,
    super.key,
  });
  final VoidCallback onBack, onTest, onQuestionnaire;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<TrainingGoalCubit>();
    return GoalPage(
      screenKey: TrainingGoalKeys.diagnosticScreen,
      title: t.treinoPlanTitle,
      onBack: onBack,
      builder: (context, view) {
        final size = cubit.testSize();
        final available = cubit.testAvailable(size);
        return [
          Text(t.treinoDiagIntro),
          const SizedBox(height: AppSpacing.lg),
          LucenaCard(
            onTap: available
                ? () async {
                    if (await cubit.chooseTest()) onTest();
                  }
                : null,
            child: Column(
              key: TrainingGoalKeys.diagnosticTest,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.treinoDiagTest,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(t.treinoDiagTestSub(size)),
              ],
            ),
          ),
          if (!available)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                t.treinoDiagOffline,
                key: TrainingGoalKeys.diagnosticOffline,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          LucenaCard(
            onTap: () async {
              if (await cubit.chooseQuestionnaire()) onQuestionnaire();
            },
            child: Column(
              key: TrainingGoalKeys.diagnosticQuestionnaire,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.treinoDiagQuest,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(t.treinoDiagQuestSub),
              ],
            ),
          ),
        ];
      },
    );
  }
}
