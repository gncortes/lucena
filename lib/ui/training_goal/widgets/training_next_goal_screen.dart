import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/goal/training_objective.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_card.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_page.dart';

/// Próximo objetivo (H-TRE-15): outro torneio ou "Só quero melhorar".
class TrainingNextGoalScreen extends StatelessWidget {
  const TrainingNextGoalScreen({
    required this.onBack,
    required this.onTournament,
    required this.onImprove,
    super.key,
  });
  final VoidCallback onBack, onTournament, onImprove;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<TrainingGoalCubit>();
    return GoalPage(
      screenKey: TrainingGoalKeys.nextGoalScreen,
      title: t.treinoNextGoalTitle,
      onBack: onBack,
      builder: (context, view) => [
        LucenaCard(
          onTap: onTournament,
          child: Column(
            key: TrainingGoalKeys.nextGoalTournament,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.treinoGoalTournament,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(t.treinoGoalTournamentSub),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LucenaCard(
          onTap: () async {
            if (await cubit.nextGoal(kind: ObjectiveKind.improve)) {
              onImprove();
            }
          },
          child: Column(
            key: TrainingGoalKeys.nextGoalImprove,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.treinoGoalImprove,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(t.treinoGoalImproveSub),
            ],
          ),
        ),
      ],
    );
  }
}
