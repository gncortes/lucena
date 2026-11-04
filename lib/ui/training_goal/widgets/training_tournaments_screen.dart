import 'package:flutter/material.dart';

import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_card.dart';
import 'goal_format.dart';
import 'goal_page.dart';

/// Meus torneios (H-TRE-16 / H-TRE-14): lista com o mais recente primeiro.
class TrainingTournamentsScreen extends StatelessWidget {
  const TrainingTournamentsScreen({
    required this.onBack,
    required this.onRegister,
    super.key,
  });
  final VoidCallback onBack, onRegister;

  String _tenths(int tenths) =>
      tenths % 10 == 0 ? '${tenths ~/ 10}' : '${tenths ~/ 10},${tenths % 10}';

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return GoalPage(
      screenKey: TrainingGoalKeys.tournamentsScreen,
      title: t.treinoMyTournaments,
      onBack: onBack,
      builder: (context, view) {
        final list = [...view.tournaments]
          ..sort((a, b) => b.date.compareTo(a.date));
        if (list.isEmpty) {
          return [
            Text(
              t.treinoTournamentsEmptyTitle,
              key: TrainingGoalKeys.tournamentsEmpty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(t.treinoTournamentsEmptyBody, textAlign: TextAlign.center),
          ];
        }
        return [
          for (final r in list)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: LucenaCard(
                child: Column(
                  key: TrainingGoalKeys.tournamentRow(r.id),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(civilLong(context, r.date)),
                    Text(
                      t.treinoTournamentRow(
                        _tenths(r.tenthsPoints),
                        '${r.rounds}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ];
      },
      footer: (context, view) => BusyButton(
        buttonKey: TrainingGoalKeys.tournamentsRegister,
        label: t.treinoRegisterTournament,
        onPressed: onRegister,
      ),
    );
  }
}
