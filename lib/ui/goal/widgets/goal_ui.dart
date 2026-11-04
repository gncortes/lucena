import 'package:flutter/material.dart';

import '../../../domain/models/goal_preference.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/keys/goal_keys.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/choice_card.dart';

/// Ícone, nome e texto de cada objetivo, na pergunta e na folha do Perfil.
extension GoalPreferenceUi on GoalPreference {
  IconData get icon => switch (this) {
    GoalPreference.learn => Icons.school,
    GoalPreference.improve => Icons.auto_stories,
    GoalPreference.train => Icons.grid_view,
    GoalPreference.explore => Icons.grid_on,
    GoalPreference.challenge => Icons.hiking,
  };

  String title(AppLocalizations l10n) => switch (this) {
    GoalPreference.learn => l10n.goalLearnTitle,
    GoalPreference.improve => l10n.goalImproveTitle,
    GoalPreference.train => l10n.goalTrainTitle,
    GoalPreference.explore => l10n.goalExploreTitle,
    GoalPreference.challenge => l10n.goalChallengeTitle,
  };

  String text(AppLocalizations l10n) => switch (this) {
    GoalPreference.learn => l10n.goalLearnText,
    GoalPreference.improve => l10n.goalImproveText,
    GoalPreference.train => l10n.goalTrainText,
    GoalPreference.explore => l10n.goalExploreText,
    GoalPreference.challenge => l10n.goalChallengeText,
  };
}

/// Os cartões, um embaixo do outro, com [selected] marcado.
class GoalOptions extends StatelessWidget {
  const GoalOptions({
    super.key,
    required this.l10n,
    required this.selected,
    required this.onSelected,
    this.without = const {},
  });

  final AppLocalizations l10n;
  final GoalPreference selected;
  final ValueChanged<GoalPreference> onSelected;

  /// As opções que não aparecem.
  final Set<GoalPreference> without;

  @override
  Widget build(BuildContext context) {
    final shown = GoalPreference.values
        .where((goal) => !without.contains(goal))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, goal) in shown.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          ChoiceCard(
            key: GoalKeys.option(goal),
            icon: goal.icon,
            title: goal.title(l10n),
            body: goal.text(l10n),
            selected: goal == selected,
            onTap: () => onSelected(goal),
          ),
        ],
      ],
    );
  }
}
